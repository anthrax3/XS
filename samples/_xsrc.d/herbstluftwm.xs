fn 3up {
	.d '3 frames'
	.c 'wm'
	.r 'barre boc dual em hc mons osd quad r updres wmb'
	%only-X
	herbstclient load '(split horizontal:0.333333:1 (clients vertical:0)
		(split horizontal:0.500000:1
			(clients vertical:0) (clients vertical:0)))'
}
fn bari {
	.d 'Status bar indicator description'
	.c 'wm'
	.r '3up barre boc dual em hc mons osd quad r updres wmb'
	%only-X
	%with-terminal {~/.config/herbstluftwm/panel.xs legend color|less -RXi}
}
fn barre {
	.d 'Status bar restart'
	.c 'wm'
	.r '3up bari boc dual em hc mons osd quad r updres wmb'
	%only-X
	let (hc = herbstclient) {
		hc emit_hook quit_panel
		~/.config/herbstluftwm/load_panels
	}
}
fn boc {|*|
	.d 'Bell on completion'
	.a 'COMMAND'
	.c 'wm'
	.r '3up bari barre dual em hc mons osd quad r updres wmb'
	%only-X
	unwind-protect {$*} {printf %c \a}
}
fn dual {|*|
	.d 'Divide focused monitor'
	.a 'horizontal|vertical'
	.c 'wm'
	.r '3up bari barre boc em hc mons osd quad r updres wmb'
	%only-X
	let ((xo yo w h) = `{hc monitor_rect}; \
			ml = `{hc list_monitors|cut -d' ' -f2}) {
		let (hw = `($w/2); hh = `($h/2); \
				cmr = $w^x^$h^+^$xo^+^$yo; sm; nml) {
			if {~ $* <={%prefixes vertical}} {
				sm = $hw^x^$h^+^$xo^+^$yo \
					$hw^x^$h^+^`($xo+$hw)^+$yo
			} else if {~ $* <={%prefixes horizontal}} {
				sm = $w^x^$hh^+^$xo^+^$yo \
					$w^x^$hh^+^$xo ^+^`($yo+$hh)
			}
			for m $ml {
				if {~ $m $cmr} {
					nml = $nml $sm
				} else {nml = $nml $m}
			}
			hc set_monitors $nml
		}
	}
	barre
}
fn em {|*|
	.d 'Enable monitors'
	.a 'internal|external  # first and second in xrandr list'
	.a 'both [internal|external]  # primary: default = external'
	.c 'wm'
	.r '3up bari barre boc dual hc mons osd quad r updres wmb'
	%only-X
	let (p; hc = herbstclient; \
		mnl = `{xrandr|grep '^[^ ]\+ connected' \
			|cut -d' ' -f1}) {
		if {~ $* <={%prefixes both}} {
			if {~ $#mnl 1} {throw error em 'one monitor'}
			xrandr --output $mnl(1) --auto --left-of $mnl(2) \
				--output $mnl(2) --auto
			if {~ $#* 2} {
				if {~ $*(2) <={%prefixes external}} {
					p = 2
				} else if {~ $*(2) <={%prefixes internal}} {
					p = 1
				} else {
					throw error em 'both internal|external'
				}
			} else {
				p = 2
			}
			xrandr --output $mnl($p) --primary
		} else if {~ $* <={%prefixes external}} {
			if {~ $#mnl 1} {throw error em 'one monitor'}
			xrandr --output $mnl(1) --off \
				--output $mnl(2) --auto --primary
		} else if {~ $* <={%prefixes internal}} {
			if {~ $#mnl 1} {throw error em 'one monitor'}
			xrandr --output $mnl(1) --auto --primary \
				--output $mnl(2) --off
		} else {throw error em 'internal|external|both' \
					^' [internal|external]'}
		hc lock
		hc reload
	}
	# Since we've changed monitor size, remove wallpaper.
	wallpaper
}
fn hc {|*|
	.d 'herbstclient'
	.a 'herbstclient_ARGS'
	.c 'wm'
	.r '3up bari barre boc dual em mons osd quad r updres wmb'
	%only-X
	herbstclient $*
}
fn mons {|rects|
	.d 'List or define monitors'
	.a 'WxH+X+Y ...  # define logical monitors'
	.a '(none)  # list physical and logical monitors'
	.c 'wm'
	.r '3up bari barre boc dual em hc osd quad r updres wmb'
	%only-X
	if {!~ $rects ()} {
		for r $rects {
			<<<$r grep -q '^[0-9]\{1,5\}x[0-9]\{1,5\}' \
					^'+[0-9]\{1,5\}+[0-9]\{1,5\}$' \
				|| throw error mons 'invalid rect: '^$r
		}
		herbstclient set_monitors $rects
		barre
	} else {
		let (xrinfo; rect; size; w; h; diag; f; xres; dpi; pm; _) {
			for m `{xrandr|grep '^[^ ]\+ connected .* [0-9]\+mm' \
					|cut -d' ' -f1} {
				xrinfo = `{xrandr|grep -o \^^$m^' .*[0-9]\+mm'}
				rect = `{echo $xrinfo \
						|grep -o '[0-9]\+x[0-9]\+' \
							^'+[0-9]\++[0-9]\+'}
				size = <={%argify `{echo $xrinfo \
						|grep -o '[^ ]\+ x [^ ]\+mm' \
						|tr -d ' '}}
				(w h) = <={~~ $size *mmx*mm}
				# 0 .. 0.3999... truncates
				# 0.4?... .. 0.9?... is ½
				diag = `{nickle -e \
					'sqrt('^$w^'**2+'^$h^'**2)/25.4+.1'}
				(diag f) = <={~~ $diag *.*}
				{~ $f 5* 6* 7* 8*} && \
					diag = `{printf %s%s $diag ½}
				xres = `{echo $xrinfo \
					|grep -o '^[^ ]\+ .* [0-9]\+x'}
				xres = <={~~ $xres *x}
				if {~ $w 0} {
					dpi = 0
				} else {
					dpi = <={%trunc `(25.4*$xres/$w)}
				}
				pm = `{xrandr|grep \^$m|grep -o primary}
				echo $m $rect $size $diag^" $dpi^ppi $pm
			}
			echo -- '--'
			herbstclient list_monitors|sed 's/ with [^[]\+//' \
				|sed 's/\[FOCUS\] \[LOCKED\]/ 🖵  🔒/' \
				|sed 's/\[FOCUS\]/ 🖵/' \
				|sed 's/\[LOCKED\]/ '^\u'a0'^' 🔒/'
		} |column -t -R2,3,4,5
	}
}
fn osd {|msg|
	.d 'Display message on OSD'
	.a 'MESSAGE...'
	.c 'wm'
	.r '3up bari barre boc dual em hc mons quad r updres wmb'
	%only-X
	let (fl = /tmp/panel.fifos) {
		for f `{access -f $fl && cat $fl} {
			~ $f *-osdmsg && echo $msg >$f
		}
	}
}
fn quad {
	.d 'Divide focused monitor'
	.c 'wm'
	.r '3up bari barre boc dual em hc mons osd r updres wmb'
	%only-X
	let ((xo yo w h) = `{hc monitor_rect}; \
			ml = `{hc list_monitors|cut -d' ' -f2}) {
		let (hw = `($w/2); hh = `($h/2); \
				cmr = $w^x^$h^+^$xo^+^$yo; nml) {
			for m $ml {
				if {~ $m $cmr} {
					nml = $nml \
						$hw^x^$hh^+^$xo^+^$yo \
						$hw^x^$hh^+^`($xo+$hw)^+$yo \
						$hw^x^$hh^+^$xo^+^`($yo+$hh) \
						$hw^x^$hh^+^`($xo+$hw) \
								^+^`($yo+$hh)
				} else {nml = $nml $m}
			}
			hc set_monitors $nml
		}
	}
	barre
}
fn r {
	.d 'Remove all frames'
	.c 'wm'
	.r '3up bari barre boc dual em hc mons osd quad updres wmb'
	herbstclient load '(clients vertical:0)'
}
fn updres {
	.d 'Use primary display resolution'
	.c 'wm'
	.r '3up bari barre boc dual em hc mons osd quad r wmb'
	%only-X
	.adapt-resolution
	barre
	cat <<'END'
Resolution has been adjusted to match the primary display. Programs
already running may need to be restarted to use the new resolution.
END
}
fn wmb {
	.d 'List WM bindings'
	.c 'wm'
	.r '3up bari barre boc dual em hc mons osd quad r updres'
	%only-X
	%with-terminal {herbstclient list_keybinds|sed 's/'\t'/ /g'| \
		sed 's/ /'\t'/'|column -t -s\t|less -XSi}
}
