/*
*+
*  Name:
*     smf_flat_calcflat

*  Purpose:
*     Calculate a flatfield solution

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     size_t smf_flat_calcflat( msglev_t msglev, const char flatname[],
*                   const char refrespar[], const char resistpar[],
*                   const char methpar[], const char orderpar[],
*                   const char resppar[], const char respmaskpar[],
*                   const char snrminpar[], const Grp * prvgrp,
*                   smfData *flatdata, int *status );

*  Arguments:
*     msglev = msglev_t (Given)
*        Messaging level to use for any messages.
*     flatname = const char [] (Given)
*        Name of output flatfield file. Can be NULL if no flat field file
*        should be written.
*     refrespar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the reference resistance.
*     resistpar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the group of resistance
*        values for each bolometer.
*     methpar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the flatfielding method to use.
*     orderpar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the order for polynomial fitting.
*     resppar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the name of a responsivity image
*        to be written out. Can be NULL if no image is required.
*     respmaskpar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the whether responsivity data
*        should mask the flatfield.
*     snrminpar = const char [] (Given)
*        Name of the ADAM parameter to use to determine the minimum signal-to-noise
*        ratio to use for fitting responsivity data.
*     prvgrp = const Grp * (Given)
*        Group of files contributing to the provenance for the flatfield file or
*        responsivity data (if written). Can be NULL.
*     flatdata = smfData * (Given & Returned)
*        Flatfield measurements. Expects the "da" structure to contain the heater
*        settings. (see smf_flat_mergedata or smf_flat_fastflat). On exit will
*        contain the flatfield result in the "da" structure.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Calculate the flatfield from the supplied data. The parameter names are provided
*     along with the merged flatfield data. Some parameters can be NULL.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  Notes:


*  History:
*     2010-03-09 (TIMJ):
*        Initial version

*  Copyright:
*     Copyright (C) 2010 Science and Technology Facilities Council.
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
#include "msg_par.h"
#include "par_err.h"
#include "par.h"
#include "prm_par.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"

size_t
smf_flat_calcflat( msglev_t msglev, const char flatname[],
                   const char refrespar[], const char resistpar[],
                   const char methpar[], const char orderpar[],
                   const char resppar[], const char respmaskpar[],
                   const char snrminpar[], const Grp * prvgrp,
                   smfData *flatdata, int *status ) {

  smfData * bolref = NULL;  /* Corrected bolometer data */
  smf_flatmeth flatmeth;    /* Flatfielding method */
  smfData * flatpoly = NULL;/* Polynomial expansion of fit */
  size_t i = 0;             /* Counter, index */
  size_t j;                 /* Counter */
  int order;                /* Order for polynomial flatfielding */
  size_t nbols = 0;         /* Number of bolometers */
  size_t ngood = 0;         /* Number of good responsivities */
  smfData * powref = NULL;  /* Heater power as a smfData */
  double refohms;           /* Reference resistance (ohms) */
  double *resistance = NULL;/* Resistance data for each bolometer */
  smfData * respmap = NULL; /* Responsivity data */
  int respmask = 0;         /* Mask bolometers that have bad responsivity? */
  double snrmin = 5.0;      /* Default SNR minimum value for good responsivity */

  if (*status != SAI__OK) return ngood;

  /* Get flatfield processing parameters */
  smf_flat_params( flatdata, refrespar, resistpar, methpar, orderpar,
                   &refohms, &resistance,  NULL, NULL,
                   &flatmeth, &order, status );


  /* We now have data for the various pixel heater settings.
     Generate a set of reference heater power settings in pW, and calculate the
     expected measurement from each bolometer at each power setting.
  */
  smf_flat_standardpow( flatdata, refohms, resistance,
                        &powref, &bolref, status );

  /* only need to do something if we have a POLYNOMIAL
     since TABLE is what we get straight out of standardpow */
  if (flatmeth == SMF__FLATMETH_POLY ) {
    smfData * coeffs = NULL;

    /* precondition the data prior to fitting */
    smf_flat_precondition(0, powref, bolref, status );

    smf_flat_fitpoly ( powref, bolref, order, &coeffs,
                       &flatpoly, status );

    /* now coeffs is in fact the new bolval */
    if (*status == SAI__OK && coeffs) {
      smf_close_file( &bolref, status );
      bolref = coeffs;
    }

  } else {

    /* get rid of obviously bad bolometers */
    smf_flat_precondition( 1, powref, bolref, status );
  }

  /* See if we need an output file for responsivities or some temporary
     memory */
  if (*status == SAI__OK) {
    Grp *rgrp = NULL;
    size_t rsize = 0;

    /* assume not if we do not have a parameter string */
    if (resppar) {
      kpg1Wgndf( resppar, NULL, 1, 1, "", &rgrp, &rsize, status );
      if (*status == PAR__NULL) {
        rgrp = NULL;
        errAnnul( status );
      }
    }

    /* Create the file on disk or malloc it as required.
       (units will normalise so no need for prefix) */
    smf_create_bolfile( rgrp, 1, flatdata, "Responsivity",
                        "A/W", 0, &respmap, status );
    if (rgrp) grpDelet( &rgrp, status );
  }


  /* Calculate the responsivity in Amps/Watt (using the supplied
     signal-to-noise ratio minimum */
  if (snrminpar) {
    parGet0d( snrminpar, &snrmin, status );
  }
  ngood = smf_flat_responsivity( flatmeth, respmap, snrmin, 1, powref, bolref,
                                 (flatmeth == SMF__FLATMETH_TABLE ? &flatpoly : NULL), status );

  /* Report the number of good responsivities and allow the caller
     to disable completely without being required to set the filter level */
  if (*status == SAI__OK) nbols = (bolref->dims)[0] * (bolref->dims)[1];
  if (msglev != MSG__NONE) {
    msgSeti( "NG", ngood );
    msgSeti( "NTOT", nbols );
    msgOutif( msglev, "",
              "Number of good responsivities: ^NG out of ^NTOT", status);
  }

  /* Optionally discard the calibration if the responsivity is bad */
  parGet0l( respmaskpar, &respmask, status );
  if (respmask  && *status == SAI__OK ) {
    size_t nmask = 0;
    size_t thisbol = 0;
    double *respdata = (respmap->pntr)[0];
    for (i = 0; i < nbols; i++ ) {
      if ( respdata[i] == VAL__BADD) {
        thisbol = 0;
        for (j=0; j<(bolref->dims)[2]; j++) {
          double * dpntr = (bolref->pntr)[0];
          double * vpntr = (bolref->pntr)[1];
          if (dpntr[j*nbols+i] != VAL__BADD) {
            dpntr[j*nbols+i] = VAL__BADD;
            if (vpntr) vpntr[j*nbols+i] = VAL__BADD;
            thisbol++;
          }
        }
        if (thisbol > 0) nmask++;
      }
    }
    if (msglev != MSG__NONE) {
      msgSeti( "NM", nmask);
      msgOutif( msglev, "",
                "Responsivity mask has removed an additional ^NM bolometers from the flatfield",
                status);
    }
  }

  /* Now we need to attach the flatfield result to the flatfield data */
  smf_flat_assign( 0, flatmeth, powref, bolref, flatdata, status );

  /* write out the flatfield */
  if (flatname) smf_flat_write( flatmeth, flatname, flatdata, powref, bolref, flatpoly, prvgrp, status );

  if (respmap) {
    /* write the provenance at the end since we have some problems with A-tasks
       in the pipeline causing trouble if the OUT parameter has not yet been set */
    if (respmap->file) smf_accumulate_prov( NULL, prvgrp, 1, respmap->file->ndfid, "SMURF:CALCFLAT", status );
    smf_close_file( &respmap, status );
  }

  if (bolref) smf_close_file( &bolref, status );
  if (powref) smf_close_file( &powref, status );
  if (flatpoly) smf_close_file( &flatpoly, status );
  if (resistance) resistance = smf_free( resistance, status );

  return ngood;
}