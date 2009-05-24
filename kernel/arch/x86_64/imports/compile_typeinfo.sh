cd ..
for item in kernel/runtime/std/typeinfo/*.d;
do
	echo "--> $item"
	ldc -nodefaultlib -g -I. -m64 -Ikernel/runtime/. -code-model=kernel -c $item -odbuild/dsss_objs/G/. ;\
done
cd build
