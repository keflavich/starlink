/*
*+
*  Name:
*     CALCRESP

*  Purpose:
*     Calculate bolometer responsivity from stored flatfield solution

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_calcresp( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine can calculate a bolometer responsivity image from a stored
*     flatfield solution. To calculate a new flatfield solution, use the CALCFLAT
*     command on a FLATFIELD observation.

*  Notes:
*     - Works on all raw data files. The responsivity image will be identical
*     for all files in a single observation since it is only updated following
*     a FLATFIELD observation.
*     - Provenance is *not* propagated to the output files since the output files
*     do not depend on the bolometer data.


*  ADAM Parameters:
*     IN = NDF (Read)
*          Input files to be processed. Each input file is processed
*          independently so will work with all observation files including
*          dark observations and a combination of sub-arrays.
*     MSG_FILTER = _CHAR (Read)
*          Control the verbosity of the application. Values can be
*          QUIET (minimal messages), NORMAL, VERBOSE or DEBUG [NORMAL]
*     NGOOD() = _INTEGER (Write)
*          Number of bolometers with good responsivities. Integer array, one
*          entry for each input file.
*     OUT = NDF (Write)
*          Output responsivity images.  If the input files were each taken with
*          the same stored FLATFIELD solution the output responsivity images
*          will be identical.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2009-03-27 (TIMJ):
*        Original version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2009 Science and Technology Facilities Council.
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

#include "par.h"
#include "star/grp.h"
#include "ndf.h"
#include "mers.h"
#include "sae_par.h"

#include "libsmf/smf.h"
#include "smurflib.h"

#define FUNC_NAME "smurf_calcresp"
#define TASK_NAME "CALCRESP"

void smurf_calcresp( int *status ) {

  size_t i = 0;             /* Counter, index */
  int *ngood = NULL;        /* Number of good responsivities in each output image */
  Grp *igrp = NULL;         /* Input group of files */
  Grp *ogrp = NULL;         /* Output group of files */
  size_t size;               /* Number of files in input group */
  size_t outsize;            /* Number of files in output group */

  /* Main routine */
  ndfBegin();

  /* Get input file(s) */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  if (*status != SAI__OK) goto CLEANUP;

  /* Get output file(s) */
  kpg1Wgndf( "OUT", igrp, size, size, "More output files required...",
             &ogrp, &outsize, status );

  /* Allocate some memory for the tracking of the number of good bolometers */
  ngood = smf_malloc( size, sizeof( *ngood ), 1, status );

  /* Loop over input files */
  for (i=1; i<=size; i++) {
    smfData * idata = NULL;   /* input data object */
    smfData * respmap = NULL;  /* Responsivity map */

    /* We do *not* need the data array itself, just flatfield information */
    smf_open_file( igrp, i, "READ", SMF__NOCREATE_DATA, &idata, status);

    /* Abort if we have no flatfield information */
    if (*status == SAI__OK && ! idata->da ) {
      msgSeti( "I", i);
      *status = SAI__ERROR;
      errRep("", "Unable to read flatfield information from input file ^I", status);
    }

    /* Abort if we had trouble. Alternative is to loop round to the next file but 
       it is safer to tell people there is a problem */
    if (*status != SAI__OK) break;

    /* Create an output responsivity file. */
    smf_create_respfile( ogrp, i, idata, &respmap, status );

    /* "bolref" and "powref" written by CALCFLAT correspond to parameters
       "flatcal" and "flatpar" in sc2store_wrtstream. */
    ngood[i-1] = smf_flat_responsivity( respmap, idata->da->nflat,
                                   idata->da->flatpar, idata->da->flatcal,
                                   status );

    /* Report the number of good responsivities */
    msgSeti( "NG", ngood[i-1] );
    msgSeti( "I", i );
    msgOutif( MSG__NORM, "",
              "Number of good responsivities for file ^I: ^NG", status);

    /* close file */
    if (respmap) smf_close_file( &respmap, status );

  }

  /* store number of good bolometers */
  parPut1i( "NGOOD", size, ngood, status);

  /* Tidy up after ourselves: release the resources used by the grp routines  */
 CLEANUP:
  if (igrp) grpDelet( &igrp, status);
  if (ogrp) grpDelet( &ogrp, status);
  if (ngood) ngood = smf_free( ngood, status );

  ndfEnd( status );
}
