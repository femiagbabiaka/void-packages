# This hook applies patches from "patches" directory.

_process_patch() {
	local _args= _patch= i=$1

	_args="-Np0"
	_patch=${i##*/}

	if [ -f $PATCHESDIR/${_patch}.args ]; then
		_args=$(cat $PATCHESDIR/${_patch}.args)
	elif [ -n "$patch_args" ]; then
		_args=$patch_args
	fi
	cp -f $i "$wrksrc"

	# Try to guess if its a compressed patch.
	if [[ $f =~ .gz$ ]]; then
		gunzip "$wrksrc/${_patch}"
		_patch=${_patch%%.gz}
	elif [[ $f =~ .bz2$ ]]; then
		bunzip2 "$wrksrc/${_patch}"
		_patch=${_patch%%.bz2}
	elif [[ $f =~ .diff ]]; then
		:
	elif [[ $f =~ .patch ]]; then
		:
	else
		msg_warn "$pkgver: unknown patch type: $i.\n"
		continue
	fi

	cd "$wrksrc"
	msg_normal "$pkgver: patching: ${_patch}.\n"
	patch -sl ${_args} -i ${_patch} 2>/dev/null
}

hook() {
	if [ ! -d "$wrksrc" ]; then
		return 0
	fi
	if [ -r $PATCHESDIR/series ]; then
		cat $PATCHESDIR/series | while read f; do
			_process_patch "$PATCHESDIR/$f"
		done
	else
		for f in $PATCHESDIR/*; do
			[ ! -f $f ] && continue
			if $(echo $f|grep -Eq '^.*.args$'); then
				continue
			fi
			_process_patch $f
		done
	fi
}
