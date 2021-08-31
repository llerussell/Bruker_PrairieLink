function regFrame = register_frame_phasecorr(frame, ds, ops)

fdata = fft2(frame);
regFrame = real(ifft2(fdata .* exp(1i * 2*pi*(ds(1)*ops.Ny + ds(2)*ops.Nx))));

end

