arr = [0,20,30,50,60,80]
%x(pwd)
arr.each do |val|
  %x{cp ./plotuntilfound-8lengthunits#{val}crowderpercent10000repetitions.png find#{val}.png}

end
