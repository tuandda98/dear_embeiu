var d = new Date();
var p = new Date(d.getFullYear(), d.getMonth() - 1, 1);
output.thisMonth = 'Tháng ' + (d.getMonth() + 1) + ', ' + d.getFullYear();
output.prevMonth = 'Tháng ' + (p.getMonth() + 1) + ', ' + p.getFullYear();
