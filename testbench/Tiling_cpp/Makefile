CXX := g++
CXXFLAGS := -w -O2

layer0:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer0.out -DTESTCASE_LAYER0
	./layer0.out > layer0.log

layer1:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer1.out -DTESTCASE_LAYER1 -DUSE_DEPTHWISE
	./layer1.out > layer1.log

layer2:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer2.out -DTESTCASE_LAYER2 -DUSE_DEPTHWISE
	./layer2.out > layer2.log

layer3:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer3.out -DTESTCASE_LAYER3 -DUSE_DEPTHWISE
	./layer3.out > layer3.log

layer4:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer4.out -DTESTCASE_LAYER4 -DUSE_DEPTHWISE
	./layer4.out > layer4.log

layer5:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer5.out -DTESTCASE_LAYER5 -DUSE_DEPTHWISE
	./layer5.out > layer5.log

layer6:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer6.out -DTESTCASE_LAYER6 -DUSE_DEPTHWISE
	./layer6.out > layer6.log

layer7:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer7.out -DTESTCASE_LAYER7 -DUSE_DEPTHWISE
	./layer7.out > layer7.log

layer8:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer8.out -DTESTCASE_LAYER8 -DUSE_DEPTHWISE
	./layer8.out > layer8.log

layer9:
	$(CXX) $(CXXFLAGS) tiling.cpp -o layer9.out -DTESTCASE_LAYER9
	./layer9.out > layer9.log

clean:
	rm -f *.out *.log