/*
*+
*  Name:
*     smf_filter_fromkeymap

*  Purpose:
*     Build a smfFilter from parameters given in an astKeyMap

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_filter_fromkeymap( smfFilter *filt, AstKeyMap *keymap, int *dofilt,
*                            int *status )

*  Arguments:
*     filt = smfFilter * (Given and Returned)
*        Pointer to smfFilter to be modified
*     keymap = AstKeyMap* (Given)
*        keymap containing parameters
*     dofilt = int* (Returned)
*        If true, frequency-domain filtering is required
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function builds a filter using parameters stored in an astKeyMap:
*     filt_edgelow, filt_edgehigh, filt_notchlow, filt_notchhigh
*     See description of these parameters in smf_get_cleanpar header.
*     If none of these parameters are defined, nothing is done to the
*     supplied smfFilter.
*     
*  Authors:
*     EC: Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2009-04-17 (EC):
*        Initial version.
*     {enter_further_changes_here}

*  Notes:

*  Copyright:
*     Copyright (C) 2009 University of British Columbia
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

#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "prm_par.h"
#include "par_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_filter_fromkeymap"

void smf_filter_fromkeymap( smfFilter *filt, AstKeyMap *keymap, int *dofilt,
                            int *status ) {

  int dofft=0;              /* Set if freq. domain filtering the data */
  double f_edgelow;         /* Freq. cutoff for low-pass edge filter */
  double f_edgehigh;        /* Freq. cutoff for high-pass edge filter */
  double f_notchlow[SMF__MXNOTCH]; /* Array low-freq. edges of notch filters */
  double f_notchhigh[SMF__MXNOTCH];/* Array high-freq. edges of notch filters */
  int f_nnotch=0;           /* Number of notch filters in array */
  int i;                    /* Loop counter */

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Search for filtering parameters in the keymap */
  smf_get_cleanpar( keymap, NULL, NULL, NULL, NULL, NULL, NULL, 
                    &f_edgelow, &f_edgehigh, f_notchlow, f_notchhigh, 
                    &f_nnotch, &dofft, NULL, NULL, NULL, NULL, status );

  /* Return dofilt if requested */
  if( dofilt ) {
    *dofilt = dofft;
  }

  /* If filtering parameters given, create filter  */
  if( dofft ) {
    if( f_edgelow ) {
      smf_filter_edge( filt, f_edgelow, 1, status );
    }
    
    if( f_edgehigh ) {
      smf_filter_edge( filt, f_edgehigh, 0, status );
    }
    
    if( f_nnotch ) {
      smf_filter_notch( filt, f_notchlow, f_notchhigh, f_nnotch, status );
    }    
  }
}