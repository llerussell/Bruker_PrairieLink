function [regFrame] = register_frame(frame,mean_im,yx_px,linesPerFrame,pixelsPerLine,rescaleFact,dftArg)

regFrame = 0*frame;
cycx = yx_px - round(dftregistration(mean_im,fft2(imresize(frame,rescaleFact)),dftArg)./rescaleFact);
Iyx = cycx < [0 0 linesPerFrame pixelsPerLine] & cycx > 0;
regFrame(Iyx(:,3),Iyx(:,4)) = frame(cycx(Iyx(:,3),3),cycx(Iyx(:,4),4));

end

