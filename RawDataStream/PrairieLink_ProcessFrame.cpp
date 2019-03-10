/*
 * PrairieLink ProcessFrame
 * ------------------------
 * Processes a stream of raw samples into a final frame. The following
 * processing steps are performed:
 * 1. 'Bit-shift'
 * 2. Average only >0 values
 * 3. Flip even/odd lines
 *
 * Lloyd Russell 2017
 */

#include "mex.h"

// The computational routine
void processFrame(unsigned short *inFrame, int samplesPerPixel, int linesPerFrame,
        int pixelsPerLine, int flipEvenRows, unsigned short *outFrame)
{
    // declare variables
    int i;
    int j;
    int k;
    double sampleValue;
    double pixelSum;
    int pixelCount;
    int index;
    bool doFlip = flipEvenRows;  // initialise doFlip to flip either even or odd rows
    
    // ROW LOOP
    for (i=0; i<linesPerFrame; i++) {
        
        // toggle whether or not to flip this line
        doFlip = !doFlip;
        
        // COLUMN LOOP
        for (j=0; j<pixelsPerLine; j++) {
            
            // SAMPLE LOOP
            sampleValue = 0;
            pixelSum = 0;
            pixelCount = 0;
            for (k=0; k<samplesPerPixel; k++) {
                sampleValue = inFrame[(i*linesPerFrame*samplesPerPixel) + (j*samplesPerPixel) + k];
                sampleValue -= 8192;
                if (sampleValue >= 0) {
                    pixelSum += sampleValue;
                    pixelCount += 1;
                }
            }
            
            if (doFlip) {
                index = (i*linesPerFrame) + (pixelsPerLine - 1 - j);
            }
            else {
                index = (i*linesPerFrame) + j;
            }
            outFrame[index] = pixelSum / pixelCount;
        }
    }
}

// The gateway function
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int samplesPerPixel;
    int linesPerFrame;
    int pixelsPerLine;
    int flipEvenRows;
    unsigned short *inFrame;   // 1xN input matrix
    unsigned short *outFrame;  // output matrix
    
    // create a pointer to the real data in the input matrix
    inFrame = (unsigned short *)mxGetData(prhs[0]);
    
    // get the value of the scalar input
    samplesPerPixel = mxGetScalar(prhs[1]);
    linesPerFrame   = mxGetScalar(prhs[2]);
    pixelsPerLine   = mxGetScalar(prhs[3]);
    flipEvenRows    = mxGetScalar(prhs[4]);
    
    // create the output matrix
    plhs[0] = mxCreateNumericMatrix(linesPerFrame, pixelsPerLine, mxUINT16_CLASS, mxREAL);
    
    // get a pointer to the real data in the output matrix
    outFrame = (unsigned short *)mxGetData(plhs[0]);
    
    // call the computational routine
    processFrame(inFrame, samplesPerPixel, linesPerFrame, pixelsPerLine, flipEvenRows, outFrame);
}
