#include "test_precomp.hpp"
#include <iostream>
#include "npy_blob.hpp"

namespace cvtest
{

using namespace std;
using namespace testing;
using namespace cv;
using namespace cv::dnn;

static std::string getOpenCVExtraDir()
{
    return cvtest::TS::ptr()->get_data_path();
}

template<typename TStr>
static String _tf(TStr filename)
{
    return (getOpenCVExtraDir() + "/dnn/layers/") + filename;
}

static void testLayer(String basename, bool useCaffeModel = false)
{
    Blob inp = blobFromNPY(_tf("blob.npy"));
    Blob ref = blobFromNPY(_tf(basename + ".npy"));

    String prototxt = basename + ".prototxt";
    String caffemodel = basename + ".caffemodel";

    Net net;
    {
        Ptr<Importer> importer = createCaffeImporter(_tf(prototxt), (useCaffeModel) ? _tf(caffemodel) : String());
        ASSERT_TRUE(importer != NULL);
        importer->populateNet(net);
    }

    net.setBlob(".input", inp);
    net.forward();
    Blob out = net.getBlob("output");

    EXPECT_EQ(ref.shape(), out.shape());

    Mat &mRef = ref.getMatRef();
    Mat &mOut = out.getMatRef();

    double normL1 = cvtest::norm(mRef, mOut, NORM_L1) / ref.total();
    EXPECT_LE(normL1, 0.0001);

    double normInf = cvtest::norm(mRef, mOut, NORM_INF);
    EXPECT_LE(normInf, 0.0001);
}

TEST(Layer_Test_Softmax, Accuracy)
{
     testLayer("softmax");
}

TEST(Layer_Test_LRN_spatial, Accuracy)
{
     testLayer("lrn_spatial");
}

TEST(Layer_Test_LRN_channels, Accuracy)
{
     testLayer("lrn_channels");
}

TEST(Layer_Test_Convolution, Accuracy)
{
     testLayer("convolution", true);
}

TEST(Layer_Test_InnerProduct, Accuracy)
{
     testLayer("inner_product", true);
}

TEST(Layer_Test_Pooling_max, Accuracy)
{
     testLayer("pooling_max");
}

TEST(Layer_Test_Pooling_ave, Accuracy)
{
     testLayer("pooling_ave");
}

TEST(Layer_Test_DeConvolution, Accuracy)
{
     testLayer("deconvolution", true);
}

TEST(Layer_Test_Reshape, squeeze)
{
    LayerParams params;
    params.set("axis", 2);
    params.set("num_axes", 1);

    Blob inp(BlobShape(4, 3, 1, 2));
    std::vector<Blob*> inpVec(1, &inp);
    std::vector<Blob> outVec;

    Ptr<Layer> rl = LayerRegister::createLayerInstance("Reshape", params);
    rl->allocate(inpVec, outVec);
    rl->forward(inpVec, outVec);

    EXPECT_EQ(outVec[0].shape(), BlobShape(Vec3i(4, 3, 2)));
}

TEST(Layer_Test_Reshape_Split_Slice, Accuracy)
{
    Net net;
    {
        Ptr<Importer> importer = createCaffeImporter(_tf("reshape_and_slice_routines.prototxt"));
        ASSERT_TRUE(importer != NULL);
        importer->populateNet(net);
    }

    Blob input(BlobShape(Vec2i(6, 12)));
    RNG rng(0);
    rng.fill(input.getMatRef(), RNG::UNIFORM, -1, 1);

    net.setBlob(".input", input);
    net.forward();
    Blob output = net.getBlob("output");

    normAssert(input, output);
}

}
