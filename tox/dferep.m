function dX = dferep(t, X)
  %  created 2007/10/03 by Bas Kooijman
  %
  %  routine called by ferep; similar to dfegrowth, extended with reprod
  %  feeding effects on reproduction: target is {J_XAm} or y_EX
  %
  %% Input
  %  t: exposure time (not used)
  %  X: (5 * nc,1) vector with state variables (see below)
  %
  %% Output
  %  dX: derivatives of state variables

  global C nc c0 cA ke kap kapR g kJ kM v Hb Hp
  global Lb0

  % unpack state vector
  N = X(1:nc);        % cumulative number of offspring
  H = X(nc+(1:nc));   % scaled maturity H = M_H/ {J_EAm}
  L = X(2*nc+(1:nc)); % length
  U = X(3*nc+(1:nc)); % scaled reserve U = M_E/ {J_EAm}
  c = X(4*nc+(1:nc)); % scaled internal concentration
  
  s = min(.99999,max(0,(c - c0)/ cA));  % stress factor
  % we here apply the factor (1 - s) to f

  E = U * v ./ L .^ 3;        % scaled reserve density e = m_E/m_Em (dim-less)

  Lm = v/ (kM * g);           % maximum length
  eg = E .* g ./ (E + g);   % in DEB notation: e g/ (e + g)
  SC = L .^ 2 .* eg .* (1 + L ./ (g .* Lm)); % SC = J_EC/{J_EAm}

  rB = kM * g ./ (3 * (E + g)); % von Bert growth rate
  dL = rBs .* (E .* Lms - L);    % change in length
  dU = (1 - s) .* L.^2 - SC;     % change in time-surface U = M_E/{J_EAm}
  dc = (ke * Lm .* (C - c) - 3 * dL .* c) ./ L; % change in scaled int. conc

  U0 = zeros(nc,1); % initiate scaled reserve of fresh egg
  p_U0 = [Hb/ (1 - kap); g; kJ; kM; v];
  for i = 1:nc
    [U0(i), Lb0(i)] = initial_scaled_reserve(1 - s(i),p_U0,Lb0(i));
  end
  R = ((1 - kap) * SC - kJ * Hp) * kapR ./ U0; % reprod rate in %/d
  R = (H > Hp) .* max(0,R); % make sure that R is non-negative
  dH = (1 - kap) * SC - kJ * H; % change in scaled maturity H = M_H/ {J_EAm}
  dX = [R; dH; dL; dU; dc]; % catenate derivatives in output
