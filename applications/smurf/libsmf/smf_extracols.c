/*
*+
*  Name:
*     smf_extracols

*  Purpose:
*     Determine values for the spatial projection parameters.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     void smf_extracols( smfHead *hdr, Grp *colgrp, void **cols_info, 
*                         AstKeyMap **km, int *status )

*  Arguments:
*     hdr = smfHead * (Given)
*        Pointer to the header information for the current time slice. If
*        this is NULL, the resources used by "cols_info" will be released.
*     colgrp = Grp* (Given)
*        A group holding the names of the JCMTSTATE extension items that
*        are to be used to create extra columns.  This function returns
*        without action if "colgrp" is NULL.
*     cols_info = void ** (Given)
*        The address of a pointer to data used internally within this
*        function. On initial entry, the pointer should be NULL, and a
*        non-NULL value will be returned. If "hdr" is NULL, the resoucres
*        are freed before exiting and a NULL pointer is returned.
*     km = AstKeyMap ** (Given)
*        The address of a KeyMap pointer. If a non-NULL address is given,
*        then this function will create a new KeyMap containing the
*        values for the extra columns currently stored in "cols_info".
*        No KeyMap is created if a NULL address is supplied.
*     status = int* (Given and Returned)
*        Pointer to inherited status.

*  Description:
*     This function collects values for extra columns to store in the 
*     catalogue created via the OUTCAT parameter of MAKECUBE.

*  Authors:
*     David S Berry (JAC, UCLan)
*     {enter_new_authors_here}

*  History:
*     2-JUL-2009 (DSB):
*        Initial version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2009 Science & Technology Facilities Council.
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
#include "ast.h"
#include "mers.h"
#include "star/grp.h"
#include "star/atl.h"
#include "sae_par.h"

/* SMURF includes */
#include "smf.h"

/* System includes */
#include <stddef.h>

/* Local type definitions */
typedef struct ExtracColsStore { 
   const char **name;    /* Array of pointers to column names */
   int *type;            /* Array of column data types */
   char **data;          /* Array of pointers to column data values ( "char *" 
                            is used instead of "void *" since pointer arithmetic
                            is not allowed with "void *" pointers. */
   size_t *size;         /* Array of column data sizes */
   size_t *offset;       /* Array of offsets from start of JCMTState to item */
   int ncol;             /* Number of columns */
   int nrow;             /* Number of values stored for each column */
} ExtraColsStore;

void smf_extracols( smfHead *hdr, Grp *colgrp, void **cols_info, 
                    AstKeyMap **km, int *status ){

/* Local Variables */
   ExtraColsStore *store = NULL;
   int maxcol;
   int icol;
   int irow;
   size_t size;
   char *state_ptr;

/* Check inherited status. Also check we have a group of column names. 
   If an error has occurred, we should still attempt to free the store
   structure if required, so skip to the code that frees the store, rather
   than just returning as an initial status check usually does. */
   if( *status == SAI__OK && colgrp ) {

/* If we do not yet have a store for the extra values, create one now. */  
      if( ! *cols_info ) {
         store = astMalloc( sizeof( ExtraColsStore ) );
         if( store ) {
            maxcol = grpGrpsz( colgrp, status );
            store->name = astMalloc( sizeof( const char * )*maxcol );
            store->type = astMalloc( sizeof( int )*maxcol );
            store->size = astMalloc( sizeof( size_t )*maxcol );
            store->offset = astMalloc( sizeof( size_t )*maxcol );
            store->data = astMalloc( sizeof( char * )*maxcol );
            store->ncol = 0;
            store->nrow = 0;
   
            if( *status == SAI__OK ) {

/* Make sure the group is case insensitive. */
               grpSetcs( colgrp, 0, status );

/* Define a macro that will check the supplied group for a given
   JCMTSTATE extension item, and if found, append the item to the list of
   extra columns. The value for an item within a JCMTState structure is 
   found by storing its offset into the structure. */

#define CHECK_ITEM(Name,Type,Size,Comp) \
               if( grpIndex( Name, colgrp, 1, status ) ) { \
                  (store->name)[ store->ncol ] = Name; \
                  (store->type)[ store->ncol ] = Type; \
                  (store->size)[ store->ncol ] = Size; \
                  (store->offset)[ store->ncol ] = offsetof( JCMTState, Comp );\
                  (store->data)[ store->ncol ] = NULL; \
                  (store->ncol)++; \
               }

/* Use this macro to check for each JCMTSTATE item. */
               CHECK_ITEM("ACS_EXPOSURE",AST__FLOATTYPE,sizeof(float),acs_exposure ) 
               CHECK_ITEM("ACS_NO_NEXT_REF",AST__INTTYPE,sizeof(int),acs_no_next_ref ) 
               CHECK_ITEM("ACS_NO_ONS",AST__INTTYPE,sizeof(int),acs_no_ons) 
               CHECK_ITEM("ACS_NO_PREV_REF",AST__INTTYPE,sizeof(int),acs_no_prev_ref) 
               CHECK_ITEM("ACS_OFFEXPOSURE",AST__FLOATTYPE,sizeof(float),acs_offexposure) 
               CHECK_ITEM("ACS_SOURCE_RO",AST__STRINGTYPE,sizeof(char)*JCMT__SZACS_SOURCE_RO+1,acs_source_ro)
               CHECK_ITEM("ENVIRO_AIR_TEMP",AST__FLOATTYPE,sizeof(float),enviro_air_temp) 
               CHECK_ITEM("ENVIRO_PRESSURE",AST__FLOATTYPE,sizeof(float),enviro_pressure) 
               CHECK_ITEM("ENVIRO_REL_HUM",AST__FLOATTYPE,sizeof(float),enviro_rel_hum) 
               CHECK_ITEM("FE_DOPPLER",AST__DOUBLETYPE,sizeof(double),fe_doppler) 
               CHECK_ITEM("FE_LOFREQ",AST__DOUBLETYPE,sizeof(double),fe_lofreq) 
               CHECK_ITEM("FTS_POS",AST__FLOATTYPE,sizeof(float),fts_pos) 
               CHECK_ITEM("JOS_DRCONTROL",AST__INTTYPE,sizeof(int),jos_drcontrol) 
               CHECK_ITEM("POL_ANG",AST__DOUBLETYPE,sizeof(double),pol_ang) 
               CHECK_ITEM("RTS_END",AST__DOUBLETYPE,sizeof(double),rts_end) 
               CHECK_ITEM("RTS_NUM",AST__INTTYPE,sizeof(int),rts_num) 
               CHECK_ITEM("RTS_TASKS",AST__STRINGTYPE,sizeof(char)*JCMT__SZRTS_TASKS+1,rts_tasks)
               CHECK_ITEM("SC2_HEAT",AST__INTTYPE,sizeof(int),sc2_heat) 
               CHECK_ITEM("SMU_AZ_CHOP_X",AST__DOUBLETYPE,sizeof(double),smu_az_chop_x) 
               CHECK_ITEM("SMU_AZ_CHOP_Y",AST__DOUBLETYPE,sizeof(double),smu_az_chop_y) 
               CHECK_ITEM("SMU_AZ_JIG_X",AST__DOUBLETYPE,sizeof(double),smu_az_jig_x) 
               CHECK_ITEM("SMU_AZ_JIG_Y",AST__DOUBLETYPE,sizeof(double),smu_az_jig_y) 
               CHECK_ITEM("SMU_CHOP_PHASE",AST__STRINGTYPE,sizeof(char)*JCMT__SZSMU_CHOP_PHASE+1,smu_chop_phase)
               CHECK_ITEM("SMU_JIG_INDEX",AST__INTTYPE,sizeof(int),smu_jig_index) 
               CHECK_ITEM("SMU_TR_CHOP_X",AST__DOUBLETYPE,sizeof(double),smu_tr_chop_x) 
               CHECK_ITEM("SMU_TR_CHOP_Y",AST__DOUBLETYPE,sizeof(double),smu_tr_chop_y) 
               CHECK_ITEM("SMU_TR_JIG_X",AST__DOUBLETYPE,sizeof(double),smu_tr_jig_x) 
               CHECK_ITEM("SMU_TR_JIG_Y",AST__DOUBLETYPE,sizeof(double),smu_tr_jig_y) 
               CHECK_ITEM("SMU_X",AST__DOUBLETYPE,sizeof(double),smu_x) 
               CHECK_ITEM("SMU_Y",AST__DOUBLETYPE,sizeof(double),smu_y) 
               CHECK_ITEM("SMU_Z",AST__DOUBLETYPE,sizeof(double),smu_z) 
               CHECK_ITEM("TCS_AIRMASS",AST__DOUBLETYPE,sizeof(double),tcs_airmass) 
               CHECK_ITEM("TCS_AZ_AC1",AST__DOUBLETYPE,sizeof(double),tcs_az_ac1) 
               CHECK_ITEM("TCS_AZ_AC2",AST__DOUBLETYPE,sizeof(double),tcs_az_ac2) 
               CHECK_ITEM("TCS_AZ_ANG",AST__DOUBLETYPE,sizeof(double),tcs_az_ang) 
               CHECK_ITEM("TCS_AZ_BC1",AST__DOUBLETYPE,sizeof(double),tcs_az_bc1) 
               CHECK_ITEM("TCS_AZ_BC2",AST__DOUBLETYPE,sizeof(double),tcs_az_bc2) 
               CHECK_ITEM("TCS_AZ_DC1",AST__DOUBLETYPE,sizeof(double),tcs_az_dc1) 
               CHECK_ITEM("TCS_AZ_DC2",AST__DOUBLETYPE,sizeof(double),tcs_az_dc2) 
               CHECK_ITEM("TCS_BEAM",AST__STRINGTYPE,sizeof(char)*JCMT__SZTCS_BEAM+1,tcs_beam) 
               CHECK_ITEM("TCS_INDEX",AST__INTTYPE,sizeof(int),tcs_index) 
               CHECK_ITEM("TCS_PERCENT_CMP",AST__INTTYPE,sizeof(int),tcs_percent_cmp) 
               CHECK_ITEM("TCS_SOURCE",AST__STRINGTYPE,sizeof(char)*JCMT__SZTCS_SOURCE+1,tcs_source) 
               CHECK_ITEM("TCS_TAI",AST__DOUBLETYPE,sizeof(double),tcs_tai) 
               CHECK_ITEM("TCS_TR_AC1",AST__DOUBLETYPE,sizeof(double),tcs_tr_ac1) 
               CHECK_ITEM("TCS_TR_AC2",AST__DOUBLETYPE,sizeof(double),tcs_tr_ac2) 
               CHECK_ITEM("TCS_TR_ANG",AST__DOUBLETYPE,sizeof(double),tcs_tr_ang) 
               CHECK_ITEM("TCS_TR_BC1",AST__DOUBLETYPE,sizeof(double),tcs_tr_bc1) 
               CHECK_ITEM("TCS_TR_BC2",AST__DOUBLETYPE,sizeof(double),tcs_tr_bc2) 
               CHECK_ITEM("TCS_TR_DC1",AST__DOUBLETYPE,sizeof(double),tcs_tr_dc1) 
               CHECK_ITEM("TCS_TR_DC2",AST__DOUBLETYPE,sizeof(double),tcs_tr_dc2) 
               CHECK_ITEM("TCS_TR_SYS",AST__STRINGTYPE,sizeof(char)*JCMT__SZTCS_TR_SYS+1,tcs_tr_sys) 
               CHECK_ITEM("WVM_T12",AST__FLOATTYPE,sizeof(float),wvm_t12) 
               CHECK_ITEM("WVM_T42",AST__FLOATTYPE,sizeof(float),wvm_t42) 
               CHECK_ITEM("WVM_T78",AST__FLOATTYPE,sizeof(float),wvm_t78) 
               CHECK_ITEM("WVM_TIME",AST__DOUBLETYPE,sizeof(double),wvm_time) 

#undef CHECK_ITEM

/* Return a pointer to the store. */
               *cols_info = store;
            }
         }
      }

/* If we have some extra values to add to the store, add them now. */
      if( hdr && *status == SAI__OK ) {
         store = *cols_info;

/* Get a "char *" pointer to the start of the JCMTState structure in the
   supplied header. Would like to use "void *" but pointer arithmetic is
   not allowed on "void *" pointers. */
         state_ptr = (char *) ( hdr->state );

/* Record the index of the row that is about to be stored, and then
   increment the number of rows. */
         irow = (store->nrow)++;

/* Loop round each column for which values are being stored. */
         for( icol = 0; icol < store->ncol; icol++ ) {

/* Ensure the array of row values is large enough to hold another row. */
            size = (store->size)[ icol ];
            (store->data)[ icol ] = astGrow( (store->data)[ icol ], 
                                             store->nrow, size );

/* Check the pointer can be used safely. */
            if( *status == SAI__OK ) {

/* Copy the value from the header to the store. In order to avoid "void *" 
   pointer arithmetic, we assume that sizeof(char) == 1. */
               memcpy( (store->data)[ icol ] + size*irow,
                       state_ptr + (store->offset)[ icol ], size );
            }
         }
      }

/* If a KeyMap is required, create one now. */
      if( km ) {
         *km = astKeyMap( " " );

/* Loop round each column for which values have been stored. */
         store = *cols_info;
         for( icol = 0; icol < store->ncol; icol++ ) {

/* Create a vector entry of the appropriate data type in the KeyMap, and put 
   the column data values into it. */
            if( (store->type)[ icol ] == AST__INTTYPE ) {
               astMapPut1I( *km, (store->name)[ icol ], store->nrow,
                            (int *) (store->data)[ icol ], NULL );

            } else if( (store->type)[ icol ] == AST__FLOATTYPE ) {
               astMapPut1F( *km, (store->name)[ icol ], store->nrow,
                            (float *) (store->data)[ icol ], NULL );

            } else if( (store->type)[ icol ] == AST__DOUBLETYPE ) {
               astMapPut1D( *km, (store->name)[ icol ], store->nrow,
                            (double *) (store->data)[ icol ], NULL );

            } else {
               atlMapPut1S( *km, (store->name)[ icol ], (store->data)[ icol ],
                            (store->size)[ icol ], store->nrow, NULL, status );
            }
         }

      }
   }

/* If no new values were supplied, or an error has occurred, free the extra 
   values store. */
   if( ( *status != SAI__OK || !hdr ) && cols_info ) {
      store = *cols_info;
      if( store ) {

         if( store->data ) {
            for( icol = 0; icol < store->ncol; icol++ ) {
               (store->data)[ icol ] = astFree( (store->data)[ icol ] );
            }
            store->data = astFree( store->data );
         }

         store->name = astFree( store->name );
         store->type = astFree( store->type );
         store->size = astFree( store->size );
         store->offset = astFree( store->offset );
         store->ncol = 0;

         store = astFree( store );
         *cols_info = NULL;
      }
   }
}