tiling:
	g++ tiling.cpp -o tiling.out
	./tiling.out > data.log

tiling_depthswise:
	g++ tiling.cpp -o tiling_depthwise.out -DUSE_DEPTHWISE
	./tiling_depthwise.out > data.log

clean:
	rm -f *.log
	rm -f *.out