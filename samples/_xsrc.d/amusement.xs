fn cookie {
	.d 'Fortune'
	.c 'amusement'
	let (subjects = art computers cookie definitions goedel \
			humorists literature people pets platitudes \
			politics science wisdom) {
		fortune -n 200 -s $subjects
	}
}
fn wisepony {
	.d 'Wise pony'
	.c 'amusement'
	cookie|ponysay|less -eRFX
}
fn worms {|*|
	.d 'Display worms'
	.a '[worms_OPTIONS]'
	.c 'amusement'
	%with-quit {
		/usr/bin/worms -n 7 -d 50 $*
	}
}
