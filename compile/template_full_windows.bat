cd "$path\bin"
"$vbsp" -game "$path\$id" "$path\%1" -leaktest
pause
"$vvis" -game "$path\$id" "$path\%1"
"$vrad" -hdr -final -textureshadows -StaticPropLighting -StaticPropPolys -game "$path\$id" "$path\%1"
exit
