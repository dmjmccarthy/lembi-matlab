function [Xd] = SolvSimul(A, N)
%Rem To solve a set of simultaneous equts. using Gauss-Jordon substitution
%
%  Source: Technical Basic:- V. Kassab  p227

%  Elimination routine
for i = 1:N
    for j = 1:N
        if j == i
            continue, end
        %             If j = i Then GoTo nxt1
        
        if A(i, i) == 0
            A(i, i) = 0.00000001;
        end
        m = A(j, i) / A(i, i);
        for k = 1:N + 1
            A(j, k) = A(j, k) - m * A(i, k);
        end
    end
end

Xd = zeros(3,1);

%  Output routine
for i = 1:N
    Xd(i) = A(i, N + 1) / A(i, i);
end