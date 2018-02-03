function f_hat = calcFourier(component,L,varargin)
% called by ODF/calcFourier

% set parameter
c = component.weights / length(component.SS) / length(component.CS);
      
% TODO
% for a few center symmetrize before computing c_hat
if 10*length(component.center)*length(component.SS)*length(component.CS) < max(L^3,100)
  
  g = component.SS * reshape(quaternion(component.center),1,[]); % SS x S3G
  g = reshape(g.',[],1);                             % S3G x SS
  g = reshape(g*component.CS,1,[]);                        % S3G x SS x CS
  % g = quaternion(symmetrise(odf.center));
  
  c = repmat(c,1,length(component.CS)*length(component.SS));
else
  g = quaternion(component.center);
end
 
% export Chebyshev coefficients
A = component.psi.A;
A = A(1:min(max(2,L+1),length(A)));

% calculate Fourier coefficients
f_hat = gcA2fourier(g,c,A);

% for many center symmetrise f_chat
if 10*length(component.center)*length(component.SS)*length(component.CS) >= L^3
  
  if length(component.CS) ~= 1
    % symmetrize crystal symmetry
    A(1:end) = 1;
    c = ones(1,length(component.CS));
    f_hat = multiply(f_hat,gcA2fourier(component.CS,c,A),length(A)-1);
  end
  
  if length(component.SS) ~= 1
    % symmetrize specimen symmetry
    A(1:end) = 1;
    c = ones(1,length(component.SS));
    f_hat = multiply(gcA2fourier(component.SS,c,A),f_hat,length(A)-1);
  end
  
  if component.antipodal
    for l = 0:length(A)-1
      ind = deg2dim(l)+1:deg2dim(l+1);
      f_hat(ind) = 0.5* (reshape(f_hat(ind),2*l+1,2*l+1) + ...
        reshape(f_hat(ind),2*l+1,2*l+1)');
    end    
  end
  
end

end

% --------------------------------------------------------------

function c_hat = gcA2fourier(g,c,A)

plan = nfsoftmex('init',length(A)-1,length(g),0,0,4,1000,2*ceil(1.5*(length(A)+1)));
nfsoftmex('set_x',plan,Euler(g,'nfft'));
nfsoftmex('set_f',plan,c(:));
nfsoftmex('precompute',plan);
nfsoftmex('adjoint',plan);
c_hat = nfsoftmex('get_f_hat',plan);
nfsoftmex('finalize',plan);

for l = 1:length(A)-1
  
  [k1,k2] = meshgrid(-l:l,-l:l);
  k1(k1>0) = 0;
  k2(k2>0) = 0;
  s = (-1).^k1 .* (-1).^k2;
  
  ind = (deg2dim(l)+1):deg2dim(l+1);
  c_hat(ind) = A(l+1)*s.*reshape(c_hat(ind),2*l+1,2*l+1);
  
end
  
end

% --------------------------------------------------------------

% multiply Fourier matrixes
function f = multiply(f1,f2,lA)

f = zeros(numel(f1),1);
for l = 0:lA  
  ind = deg2dim(l)+1:deg2dim(l+1);  
  f(ind) = reshape(f1(ind),2*l+1,2*l+1) * ...
    reshape(f2(ind),2*l+1,2*l+1);
end

end
