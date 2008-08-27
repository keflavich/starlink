/*
*+
*  Name:
*     DREAMSOLVE

*  Purpose:
*     Top-level DREAM solver

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_dreamsolve( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine for reconstructing 2-D images from
*     DREAM observations

*  ADAM Parameters:
*     IN = NDF (Read)
*          Name of input data file
*     OUT = NDF (Write)
*          Name of output file containing DREAM images

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-06-13 (AGG):
*        Clone from smurf_makemap
*     2006-07-26 (TIMJ):
*        Remove unused sc2 includes.
*     2006-08-07 (EC):
*        Replaced sc2ast_createwcs_compat call with sc2ast_createwcs placeholder
*     2006-09-07 (EC):
*        Commented out sc2ast_createwcs placeholder due to interface change
*     2006-09-14 (AGG):
*        All processing moved into smf_dreamsolve
*     2008-07-22 (TIMJ):
*        Use kaplibs and support dark subtraction.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     Copyright (C) 2006 University of British Columbia. All Rights
*     Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

/* Standard incldues */
#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "par.h"
#include "prm_par.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/hds.h"
#include "star/ndg.h"
#include "star/grp.h"

/* SMURF includes */
#include "smurf_par.h"
#include "smurflib.h"
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

/* SC2DA includes */
#include "sc2da/sc2store_par.h"
#include "sc2da/sc2math.h"
#include "sc2da/sc2ast.h"
#include "sc2da/dream_par.h"

#define FUNC_NAME "smurf_dreamsolve"
#define TASK_NAME "DREAMSOLVE"

void smurf_dreamsolve ( int *status ) {

  /* Local Variables */
  smfArray *darks = NULL;          /* Dark data */
  Grp *fgrp = NULL;          /* Filtered group, no darks */
  size_t i;                        /* Loop counter */
  Grp *igrp = NULL;                /* Input files */
  Grp *ogrp = NULL;                /* Output files */
  size_t size;                     /* Size of input Grp */
  size_t outsize;                  /* Size of output Grp */
  smfData *data = NULL;            /* Input data */

  /* Main routine */
  ndfBegin();
  
  /* Read the input file */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  /* Filter out darks */
  smf_find_darks( igrp, &fgrp, NULL, 1, SMF__NULL, &darks, status );

  /* input group is now the filtered group so we can use that and
     free the old input group */
  size = grpGrpsz( fgrp, status );
  grpDelet( &igrp, status);
  igrp = fgrp;
  fgrp = NULL;

  if (size > 0) {
    /* Get output file(s) */
    kpg1Wgndf( "OUT", igrp, size, size, "More output files required...",
               &ogrp, &outsize, status );
  } else {
    msgOutif(MSG__NORM, " ","All supplied input frames were DARK,"
       " nothing to do", status );
  }

  /* Loop over number of files */
  for ( i=1; i<=size; i++) {
    /* Open file and flatfield the data */
    smf_open_and_flatfield( igrp, ogrp, i, darks, &data, status );
    smf_dreamsolve( data, status );

    /* Check status to see if there was a problem */
    if (*status != SAI__OK) {
      /* Tell the user which file it was... */
      msgSeti("I",i);
      msgSeti("N",size);
      errRep(FUNC_NAME, 
	     "Unable to apply DREAM solution to data from file ^I of ^N", status);
    } else {
      msgOutif(MSG__VERB," ", "DREAM solution applied", status);
    }
    /* Free resources for output data */
    smf_close_file( &data, status );
  }

  /* Free up resources */
  if (darks) smf_close_related( &darks, status );
  grpDelet( &igrp, status);
  grpDelet( &ogrp, status);

  ndfEnd( status );
}
