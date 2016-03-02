reset
# set term x11
# f(x) = 1/(500*a*(1-x))
# a = 1
# fit f(x) "ProbGegenCrowder" u 1:2 via a
# plot "ProbGegenCrowder" with errorbars, f(x), g(x)
set term png
set output "meantimes.png"
set title "Mittlere Zeiten gegen Crowderkonzentration"
set xlabel "\phi_c"
set ylabel "t"
f(x) = a /(x-1)
a = 550

fit f(x) "meanbound" u 1:2 via a
plot "meanbound" title "mittlere gebundene Zeit" w linespoints, "meanunbound" title "mittlere ungebundene Zeit" w linespoints, f(x) title "Fit"
