/*
*+
*  Name:
*     smf_find_science

*  Purpose:
*     Extract science data from an input group

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     smf_find_science(const Grp * ingrp, Grp **outgrp, Grp **darkgrp, Grp **flatgrp,
*                     int reducedark, int calcflat, smf_dtype darktype,
*                     smfArray ** darks, smfArray **fflats, int * status );

*  Arguments:
*     ingrp = const Grp* (Given)
*        Input group consisting of science and non-science observations.
*     outgrp = Grp ** (Returned)
*        Output group consisting of all the science observations. Can be
*        NULL.
*     darkgrp = Grp ** (Returned)
*        If non-null, will contain the group of dark files. Will not be
*        created if no darks were found. The group will be sorted by
*        date.
*     flatgrp = Grp ** (Returned)
*        If non-null, will contain the group of fast flat files. Will not be
*        created if no fast flats were found. The group will be sorted by
*        date.
*     reducedark = int (Given)
*        Logical, if true the darks are reduced (if needed) and converted
*        to 2d images from the time series. If false, the darks are not
*        touched. Only accessed if "darks" is true.
*     calcflat = int (Given)
*        Calculate the flatfield. Only accessed if "fflats" is non-NULL.
*     darktype = smf_dtype (Given)
*        Data type to use for reduced dark. Only accessed if "reducedark" is
*        true. SMF__NULL will indicate that the data type should be the
*        same as the input type.
*     darks = smfArray ** (Returned)
*        Pointer to smfArray* to be created and filled with darks. Must
*        be freed using smf_close_related. Can be NULL pointer if the darks
*        do not need to be used. *darks will be NULL if no darks were found. Will
*        be sorted by date.
*     fflats = smfArray ** (Returned)
*        Pointer to smfArray* to be created and filled with fast flatfield ramps.
*        Must be freed using smf_close_related. Can be NULL pointer if the flatfields
*        do not need to be returned. *fflats will be NULL if no fast flatfields
*        are found. The flatfield solution will be calculated and stored in the smfDA
*        component of each smfData if "calcflat" is true. Ramps are collapsed using
*        smf_flat_fastflat irrespective of the calcflat parameter.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine opens each of the files in the input group to read
*     the header and determine whether it is science data or non-science
*     (a dark or a fast flat) data. If it is a dark or ramp the data are read
*     and stored in the output smfArray. If it is science data
*     the group entry is copied to the output group and the
*     file is closed.

*  Notes:
*     - use smf_close_related to free the smfArray.
*     - if "outgrp" is NULL then only dark information will be returned.
*     - if both "darkgrp" and "darks" are NULL on entry, this routine
*       will simply filter out the dark frames.
*     - it is an error for "darkgrp", "outgrp" and "darks" to all be NULL.
*     - The darks will be returned in time order.
*     - Observations which have a SEQ_TYPE header and whose value differs
*       OBS_TYPE will be filtered out and not copied to outgrp. FASTFLATS
*       can optionally be copied to an output group.
*     - Observations with inconsistent SEQSTART and RTS_NUM entries will be
*       filtered out. These are commonly caused by the DA system using a
*       header from the previous file.
*     - Flatfield calculation requires access to the parameter system and
*       uses a standard set of parameters: REFRES, RESIST, FLATMETH, FLATORDER,
*       "RESPMASK" and "FLATSNR". See the CALCFLAT documentation for more details.
*       There is no facility for creating an output responsivity image.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-07-17 (TIMJ):
*        Initial version
*     2008-07-29 (TIMJ):
*        Did not realise that ndgCpsup should be used to copy entries.
*     2008-07-31 (TIMJ):
*        Report observation details.
*     2008-12-09 (TIMJ):
*        Do not react badly if a fits header is missing.
*     2009-04-24 (TIMJ):
*        Factor out observation summary reporting.
*     2009-05-25 (TIMJ):
*        Use new smf_obsmap_report API.
*     2009-09-02 (TIMJ):
*        Use smf_find_dateobs rather than directly accessing jcmtstate
*        to be a little more robust with junk files.
*     2009-09-25 (TIMJ):
*        Move sort routine externally.
*     2009-11-24 (TIMJ):
*        Quick hack to filter out SEQ_TYPE ne OBS_TYPE observations. Proper
*        solution is for an additional smfArray to be returned with these
*        items.
*     2010-01-14 (TIMJ):
*        Ignore files that have corrupt FITS header by seeing if the first RTS_NUM
*        matches the SEQSTART value.
*     2010-02-18 (TIMJ):
*        Rename to smf_find_science from smf_find_darks.

*  Copyright:
*     Copyright (C) 2008-2010 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

/* System includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "msg_par.h"
#include "star/one.h"
#include "ast.h"
#include "star/one.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_find_science"

size_t
smf__addto_sortinfo ( const smfData * indata, smfSortInfo allinfo[], size_t index,
                      size_t counter, const char * type, int *status );


void smf_find_science(const Grp * ingrp, Grp **outgrp, Grp **darkgrp, Grp **flatgrp,
                      int reducedark, int calcflat, smf_dtype darktype,
                      smfArray ** darks, smfArray **fflats, int * status ) {

  smfSortInfo *alldarks; /* array of sort structs for darks */
  smfSortInfo *allfflats; /* array of fast flat info */
  Grp * dgrp = NULL;  /* Internal dark group */
  size_t dkcount = 0; /* Dark counter */
  size_t ffcount = 0; /* Fast flat counter */
  Grp * fgrp = NULL;  /* Fast flat group */
  size_t i;           /* loop counter */
  smfData *infile = NULL; /* input file */
  size_t insize;     /* number of input files */
  AstKeyMap * obsmap = NULL; /* Info from all observations */
  AstKeyMap * objmap = NULL; /* All the object names used */
  Grp *ogrp = NULL;   /* local copy of output group */
  size_t sccount = 0; /* Number of accepted science files */

  if (outgrp) *outgrp = NULL;
  if (darkgrp) *darkgrp = NULL;
  if (darks) *darks = NULL;
  if (fflats) *fflats = NULL;

  if (*status != SAI__OK) return;

  /* Sanity check to make sure we return some information */
  if ( outgrp == NULL && darkgrp == NULL && darks == NULL && fflats == NULL) {
    *status = SAI__ERROR;
    errRep( " ", FUNC_NAME ": Must have some non-NULL arguments"
            " (possible programming error)", status);
    return;
  }

  /* Create new group for output files */
  ogrp = grpNew( "Science", status );

  /* and a new group for darks */
  dgrp = grpNew( "DarkFiles", status );

  /* and for fast flats */
  fgrp = grpNew( "FastFlats", status );

  /* and also create a keymap for the observation description */
  obsmap = astKeyMap( " " );

  /* and an object map */
  objmap = astKeyMap( " " );

  /* Work out how many input files we have and allocate sufficient sorting
     space */
  insize = grpGrpsz( ingrp, status );
  alldarks = smf_malloc( insize, sizeof(*alldarks), 1, status );
  allfflats = smf_malloc( insize, sizeof(*allfflats), 1, status );

  /* check each file in turn */
  for (i = 1; i <= insize; i++) {

    /* open the file but just to get the header */
    smf_open_file( ingrp, i, "READ", SMF__NOCREATE_DATA, &infile, status );
    if (*status != SAI__OK) break;

    /* Fill in the keymap with observation details */
    smf_obsmap_fill( infile, obsmap, objmap, status );

    if (smf_isdark( infile, status )) {
      /* Store the sorting information */
      dkcount = smf__addto_sortinfo( infile, alldarks, i, dkcount, "Dark", status );
    } else {
      /* compare sequence type with observation type and drop it (for now)
         if they differ */
      if ( infile->hdr->obstype == infile->hdr->seqtype ) {
        /* Sanity check the header for corruption. Compare RTS_NUM with SEQSTART */
        int seqstart = 0;
        JCMTState *tmpState = NULL;
        smf_getfitsi( infile->hdr, "SEQSTART", &seqstart, status );
        tmpState = infile->hdr->allState;
        msgSetc("F", infile->file->name);
        if ( (tmpState[0]).rts_num == seqstart ) {
          /* store the file in the output group */
          ndgCpsup( ingrp, i, ogrp, status );
          msgOutif(MSG__DEBUG, " ", "Non-dark file: ^F",status);
          sccount++;
        } else {
          msgOutif( MSG__QUIET, "", "File ^F has a corrupt FITS header. Ignoring it.", status );
        }
      } else if (infile->hdr->seqtype == SMF__TYP_FASTFLAT ) {
        /* Assume these are fast ramps - need to put them in a sort struct */
        ffcount = smf__addto_sortinfo( infile, allfflats, i, ffcount, "Fast flat", status );
      } else {
        msgSetc("F", infile->file->name);
        msgOutif(MSG__DEBUG, " ", "Sequence type mismatch with observation type: ^F",status);
      }
    }

    /* close the file */
    smf_close_file( &infile, status );
  }

  /* Store output group in return variable or else free it */
  if (outgrp) {
    *outgrp = ogrp;
  } else {
    grpDelet( &ogrp, status );
  }

  /* process flatfields if necessary */
  if (ffcount > 0 && fflats ) {
    smfArray * array = NULL;

    /* sort flats into order */
    qsort( allfflats, ffcount, sizeof(*allfflats), smf_sort_bytime);

    if (fflats) array = smf_create_smfArray( status );

    /* now open the flats and store them if requested */
    if (*status == SAI__OK) {
      for (i = 0; i < ffcount; i++ ) {
        size_t ori_index =  (allfflats[i]).index;

        /* Store the entry in the output group */
        ndgCpsup( ingrp, ori_index, fgrp, status );

        if (array) {
          smfData * outfile = NULL;

          /* read filename from new group */
          smf_open_file( fgrp, i+1, "READ", 0, &infile, status );

          /* Collapse it */
          smf_flat_fastflat( infile, &outfile, status );
          if (outfile) {
            smf_close_file( &infile, status );
            infile = outfile;

            if (calcflat) {
              (void)smf_flat_calcflat( MSG__VERB, NULL, "REFRES", "RESIST",
                                       "FLATMETH", "FLATORDER", NULL, "RESPMASK",
                                       "FLATSNR", NULL, infile, status );
            }

          }

          smf_addto_smfArray( array, infile, status );
        }
      }
      if (fflats) *fflats = array;
    }
  }

  /* no need to do any more if neither darks nor darkgrp are defined */
  if (dkcount > 0 && (darks || darkgrp) ) {
    smfArray * array = NULL;

    /* sort darks into order */
    qsort( alldarks, dkcount, sizeof(*alldarks), smf_sort_bytime);

    if (darks) array = smf_create_smfArray( status );

    /* now open the darks and store them if requested */
    if (*status == SAI__OK) {
      for (i = 0; i < dkcount; i++ ) {
        size_t ori_index =  (alldarks[i]).index;

         /* Store the entry in the output group */
        ndgCpsup( ingrp, ori_index, dgrp, status );

        if (darks) {

          /* read the value from the new group */
          smf_open_file( dgrp, i+1, "READ", 0, &infile, status );

          /* do we have to process these darks? */
          if (reducedark) {
            smfData *outfile = NULL;
            smf_reduce_dark( infile, darktype, &outfile, status );
            if (outfile) {
              smf_close_file( &infile, status );
              infile = outfile;
            }
          }

          smf_addto_smfArray( array, infile, status );
        }
      }
      if (darks) *darks = array;
    }
  }

  /* free memory */
  alldarks = smf_free( alldarks, status );
  allfflats = smf_free( allfflats, status );

  /* Store the output groups in the return variable or free it */
  if (darkgrp) {
    *darkgrp = dgrp;
  } else {
    grpDelet( &dgrp, status);
  }
  if (flatgrp) {
    *flatgrp = fgrp;
  } else {
    grpDelet( &fgrp, status);
  }

  msgSeti( "ND", sccount );
  msgSeti( "DK", dkcount );
  msgSeti( "FF", ffcount );
  msgSeti( "TOT", insize );
  if ( insize == 1 ) {
    if (dkcount == 1) {
      msgOutif( MSG__VERB, " ", "Single input file was a dark",
                status);
    } else if (ffcount == 1) {
      msgOutif( MSG__VERB, " ", "Single input file was a fast flatfield",
                status);
    } else if (sccount == 1) {
      msgOutif( MSG__VERB, " ", "Single input file was accepted (observation type same as sequence type)",
                status);
    } else {
      msgOutif( MSG__VERB, " ", "Single input file was not accepted.",
                status);
    }

  } else {
    if (dkcount == 1) {
      msgSetc( "DKTXT", "was a dark");
    } else {
      msgSetc( "DKTXT", "were darks");
    }
    if (ffcount == 1) {
      msgSetc( "FFTXT", "was a fast flat");
    } else {
      msgSetc( "FFTXT", "were fast flats");
    }
    if (sccount == 1) {
      msgSetc( "NDTXT", "was science");
    } else {
      msgSetc( "NDTXT", "were science");
    }

    /* This might be a useful message */
    msgOutif( MSG__NORM, " ", "Out of ^TOT input files, ^DK ^DKTXT, ^FF ^FFTXT "
              "and ^ND ^NDTXT", status );
  }

  /* Now report the details of the observation */
  smf_obsmap_report( MSG__NORM, obsmap, objmap, status );

  obsmap = astAnnul( obsmap );
  objmap = astAnnul( objmap );

  return;
}


/* Routine to put info from smfData into a sort struct. "index" is the index
   in the input group. "counter" is the current position to use to store
   the item. Returns the next index to be used (ie updated counter). */

size_t
smf__addto_sortinfo ( const smfData * indata, smfSortInfo allinfo[], size_t index,
                      size_t counter, const char * type, int *status ) {
  smfSortInfo * sortinfo = NULL;

  if (*status != SAI__OK) return counter;

  /* store the name and time in the struct */
  sortinfo = &(allinfo[counter]);
  one_strlcpy( sortinfo->name, indata->file->name, sizeof(sortinfo->name),
               status );
  smf_find_dateobs( indata->hdr, &(sortinfo->mjd), NULL, status );
  msgOutiff(MSG__DEBUG, " ", "%s file: %s",status,
            type, indata->file->name);
  sortinfo->index = index;
  counter++;
  return counter;
}