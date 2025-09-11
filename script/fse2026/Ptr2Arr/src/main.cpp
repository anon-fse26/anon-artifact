#include "clang/Tooling/Tooling.h"
#include "clang/Tooling/CommonOptionsParser.h"

#include "../include/pointer_visitor/pointer_action.h"
#include "../include/points_to_analysis/points_to_analysis.h"
#include "../include/memory_analysis/memory_analysis.h"
#include "../include/code_visitor_and_rewriter/code_action.h"
#include "../include/bit_expression_visitor_and_rewriter/bit_expression_action.h"


int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: ./Ptr2Arr <path/to/SourceCode.c>\n";
        return 1;
    }

    std::filesystem::path sourceCodePath = std::filesystem::canonical(argv[1]);
    std::ifstream sourceCodeStream(sourceCodePath);
    if (!sourceCodeStream) {
        std::cerr << strerror(errno) << ": " << sourceCodePath << std::endl;
        return 1;
    }

    std::vector<std::string> clangArgs = {
        "-xc",
        "-I/usr/lib/llvm-14/lib/clang/14.0.6/include",
    };

    sourceCodeName = sourceCodePath.stem().string();
    outputDirectory = std::filesystem::current_path();

    WriteToFile(""); // ToDo: Clear the content of the output file.

    std::ifstream newSourceCodeStream(sourceCodePath);
    std::stringstream sourceCodeBuffer;
    sourceCodeBuffer << newSourceCodeStream.rdbuf();
    std::string sourceCodeFile = sourceCodeBuffer.str();

    std::string command_DG = "clang-14 -c -emit-llvm -fno-discard-value-names " + sourceCodePath.string() + " -o " + outputDirectory.string() + "/" + sourceCodeName + "_Ptr2Arr.bc && "
                             "llvm-pta-dump -pta fs -ir " + outputDirectory.string() + "/" + sourceCodeName + "_Ptr2Arr.bc > " + outputDirectory.string() + "/" + sourceCodeName + "_PointsToSets.txt";
    int result_DG = system(command_DG.c_str());
    if (result_DG != 0) {
        std::cerr << "DG execution failed." << "\n";
        return 1;
    }

    const std::string pointsToSetsPath = outputDirectory / (sourceCodeName + "_PointsToSets.txt");
    std::ifstream pointsToSetsStream(pointsToSetsPath);
    std::stringstream pointsToSetsBuffer;
    pointsToSetsBuffer << pointsToSetsStream.rdbuf();

    std::vector<PointsToSet> pointsToSets;
    clang::tooling::runToolOnCodeWithArgs(std::make_unique<PointerAction>(pointsToSets), sourceCodeFile, clangArgs);
    PointsToAnalysis pointsToAnalysis(pointsToSetsBuffer, pointsToSets);
    pointsToAnalysis.ConstructPointsToSets();

    std::vector<MemorySet> memorySets;
    MemoryAnalysis memoryAnalysis(pointsToSets, memorySets);
    memoryAnalysis.ConstructMemorySets();

    clang::tooling::runToolOnCodeWithArgs(std::make_unique<CodeAction>(memorySets), sourceCodeFile, clangArgs);

    const std::string outPath = outputDirectory / (sourceCodeName + "_Ptr2Arr.c");
    std::ifstream outStream(outPath);
    std::stringstream outBuffer;
    outBuffer << outStream.rdbuf();
    std::string outFile = outBuffer.str();
    clang::tooling::runToolOnCodeWithArgs(std::make_unique<BitExpressionAction>(), outFile,clangArgs);

    return 0;
}