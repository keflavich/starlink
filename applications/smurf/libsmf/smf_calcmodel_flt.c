/*
*+
*  Name:
*     smf_calcmodel_flt

*  Purpose:
*     Calculate the frequency domain FiLTered data model

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_calcmodel_flt( smfDIMMData *dat, int chunk, AstKeyMap *keymap, 
*			 smfArray **allmodel, int flags, int *status)

*  Arguments:
*     dat = smfDIMMData * (Given)
*        Struct of pointers to information required by model calculation
*     chunk = int (Given)
*        Index of time chunk in allmodel to be calculated
*     keymap = AstKeyMap * (Given)
*        Parameters that control the iterative map-maker
*     allmodel = smfArray ** (Returned)
*        Array of smfArrays (each time chunk) to hold result of model calc
*     flags = int (Given )
*        Control flags: not used 
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Execute a frequency domain filter, but store what was removed with a
*     time-domain representation for easy visualization. The data should
*     already have been padded/apodized in a pre-processing step.

*  Notes:

*  Authors:
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2009-03-10 (EC):
*        Initial Version
*     {enter_further_changes_here}


*  Copyright:
*     Copyright (C) 2009 University of British Columbia.
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

/* Starlink includes */
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_calcmodel_flt"

void smf_calcmodel_flt( smfDIMMData *dat, int chunk, AstKeyMap *keymap, 
			smfArray **allmodel, int flags, int *status) {

  /* Local Variables */
  size_t bstride;               /* bolo stride */
  smfFilter *filt=NULL;         /* Pointer to filter struct */
  size_t i;                     /* Loop counter */
  dim_t idx=0;                  /* Index within subgroup */
  size_t j;                     /* Loop counter */
  smfArray *model=NULL;         /* Pointer to model at chunk */
  double *model_data=NULL;      /* Pointer to DATA component of model */
  dim_t nbolo=0;                /* Number of bolometers */
  dim_t ndata=0;                /* Total number of data points */
  dim_t ntslice=0;              /* Number of time slices */
  smfArray *qua=NULL;           /* Pointer to QUA at chunk */
  unsigned char *qua_data=NULL; /* Pointer to quality data */
  smfArray *res=NULL;           /* Pointer to RES at chunk */
  double *res_data=NULL;        /* Pointer to DATA component of res */
  size_t tstride;               /* Time slice stride in data array */
                                   
  /* Main routine */
  if (*status != SAI__OK) return;

  /* Obtain pointers to relevant smfArrays for this chunk */
  res = dat->res[chunk];
  qua = dat->qua[chunk];
  model = allmodel[chunk];
  
  /* Assert bolo-ordered data */
  for( idx=0; idx<res->ndat; idx++ ) if (*status == SAI__OK ) {
    smf_dataOrder( res->sdata[idx], 0, status );
    smf_dataOrder( qua->sdata[idx], 0, status );
    smf_dataOrder( model->sdata[idx], 0, status );
  }

  /* Loop over index in subgrp (subarray) and put the previous iteration
     of the filtered component back into the residual before calculating
     and removing the new filtered component */
  for( idx=0; (*status==SAI__OK)&&(idx<res->ndat); idx++ ) {
    /* Obtain dimensions of the data */
    smf_get_dims( res->sdata[idx],  NULL, NULL, &nbolo, &ntslice, 
                  &ndata, &bstride, &tstride, status);
      
    /* Get pointers to data/quality/model */
    res_data = (res->sdata[idx]->pntr)[0];
    qua_data = (qua->sdata[idx]->pntr)[0];
    model_data = (model->sdata[idx]->pntr)[0];

    if( (res_data == NULL) || (model_data == NULL) || (qua_data == NULL) ) {
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME ": Null data in inputs", status);      
    } else {

      /* Create a filter */
      filt = smf_create_smfFilter( res->sdata[idx], status );

      smf_filter_edge( filt, 0.2, 0, status ); /* KLUDGE */
      smf_filter_edge( filt, 20, 1, status );

      if( *status == SAI__OK ) {
        /* Place last iteration of filtered signal back into residual */
        for( i=0; i<nbolo; i++ ) if( !(qua_data[i*bstride]&SMF__Q_BADB) ) {
          for( j=0; j<ntslice; j++ ) {
            res_data[i*bstride+j*tstride] += model_data[i*bstride+j*tstride];
          }
        }

        /* Copy the residual into the model array so that we have a copy */
        memcpy( model_data, res_data, 
                ndata*smf_dtype_size(res->sdata[idx],status) );
      }

      /* Apply the filter to the residual */
      smf_filter_execute( res->sdata[idx], filt, status );

      /* Store the difference between the filtered signal and the residual
         in the model container */
      if( *status == SAI__OK ) {
        for( i=0; i<nbolo; i++ ) if( !(qua_data[i*bstride]&SMF__Q_BADB) ) {
          for( j=0; j<ntslice; j++ ) {
            model_data[i*bstride+j*tstride] -= res_data[i*bstride+j*tstride];
          }
        }
      }

      /* Free the filter */
      filt = smf_free_smfFilter( filt, status );
    }
  }
}