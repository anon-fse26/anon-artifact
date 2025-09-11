#include "../../include/code_visitor_and_rewriter/code_consumer.h"

void ReplaceTexts(const std::string& path,
                  const std::vector<std::pair<std::string, std::string>>& rules) {
    std::ifstream in(path);
    std::stringstream buf;
    buf << in.rdbuf();
    std::string content = buf.str();

    for (const auto& [src, dst] : rules) {
        size_t pos = content.find(src);
        while (pos != std::string::npos) {
            content.replace(pos, src.length(), dst);
            pos = content.find(src, pos + dst.length());
        }
    }

    std::ofstream out(path);
    out << content;
}

void CodeConsumer::HandleTranslationUnit(clang::ASTContext &Context) {
    VisitorAndRewriter.TraverseDecl(Context.getTranslationUnitDecl());
    std::error_code EC;
    llvm::raw_fd_ostream stream((outputDirectory / (sourceCodeName + "_Ptr2Arr.c")).string(), EC, llvm::sys::fs::OF_Text);
    TheRewriter.getEditBuffer(TheRewriter.getSourceMgr().getMainFileID()).write(stream);
    stream.close();

    ReplaceTexts(outputDirectory / (sourceCodeName + "_Ptr2Arr.c"), {});
}