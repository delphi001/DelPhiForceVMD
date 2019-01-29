draw delete all
color Display Background white 
axes location off
#axes location LowerLeft
proc vmd_draw_arrow {mol start end color Scale} {
    # An arrow is made of a cylinder and a cone
    set varrow [vecscale $Scale [vecsub $end $start] ]
    set end2 [vecadd $start $varrow] 

    set vradius [expr "[veclength $varrow] * 0.1" ]

    puts "varrow: {$varrow}, vlength: [veclength $varrow], vradius: $vradius"

    set middle [vecadd $start [vecscale 0.7 $varrow]]
    draw color $color
    graphics $mol cylinder $start $middle radius $vradius resolution 15 filled yes
    graphics $mol cone $middle $end2 radius [expr "$vradius * 2"] resolution 15 
    puts "ARROW IS DONE!"
}

set vl 2.0
vmd_draw_arrow 0 {0 0 0} {1 0 0} red $vl
vmd_draw_arrow 0 {0 0 0} {0 1 0} green $vl
vmd_draw_arrow 0 {0 0 0} {0 0 1} blue $vl

