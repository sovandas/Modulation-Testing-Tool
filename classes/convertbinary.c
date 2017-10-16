#include "mex.h" 
#include "matrix.h"



void convert(uint16_T * result, uint8_T * array, mwSize arraylen)
{
    mwSize i; 
    for(i = 0; i < arraylen; i = i + 2) 
    {
        result[i/2] =  (((uint16_T)array[i+1]) << 8) | ((uint16_T)array[i]);
    }
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* variable declarations here */
    
    uint8_T * array; 
    uint16_T * result; 
    mwSize arraylen; 
    mwSize dimensions[2]; 

    /* code here */
    
    if(nrhs != 2)
    {
        mexErrMsgIdAndTxt("MyToolbox:convertbinary:nrhs",
                "Two inputs required.");
    }
    
    if(nlhs != 1) 
    {
        mexErrMsgIdAndTxt("MyToolbox:convertbinary:nlhs",
                "One output required.");
    }
    
    if( !mxIsUint8(prhs[1]) )
    {
        mexErrMsgIdAndTxt("MyToolbox:convertbinary:notUint8",
                "Input matrix must be type uint8.");
    }
    
    if( mxGetNumberOfElements(prhs[1])%2 != 0  )
    {
        mexErrMsgIdAndTxt("MyToolbox:convertbinary:notmultiple2",
                "Input matrix length mult be a multiple of 2.");
    }
    if(mxGetM(prhs[1]) != 1) {
    mexErrMsgIdAndTxt("MyToolbox:convertbinary:notRowVector",
                      "Input must be a row vector.");
    }
    
    
    array = (uint8_T *)mxGetData(prhs[1]);
    arraylen = (mwSize)mxGetN(prhs[1]); 
    dimensions[0] = 1;
    dimensions[1] = (mwSize)(arraylen /2); 
    
    plhs[0] = mxCreateNumericArray(2, dimensions, mxUINT16_CLASS, mxREAL);
    
    result = (uint16_T *)mxGetData(plhs[0]);
    
    convert(result, array, arraylen);
    
    
}
