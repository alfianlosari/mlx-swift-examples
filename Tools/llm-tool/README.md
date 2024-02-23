# llm-tool

See various READMEs:

- [Llama](../../Libraries/Llama/README.md)
- [SentencePiece](../../Libraries/SentencePiece/README.md)

### Building

`llm-tool` has a few requirements that must be installed first:

```
# install sentencepiece dependency
brew install sentencepiece

# Make sure you have git-lfs installed (https://git-lfs.com)
git lfs install

# get the model weights
cd ~
git clone https://huggingface.co/mlx-community/Mistral-7B-v0.1-hf-4bit-mlx
mlx-community/quantized-gemma-7b-it
```

Then build the `llm-tool` scheme in Xcode.

### Running (Xcode)

To run this in Xcode simply press cmd-opt-r to set the scheme arguments.  For example:

```
--model $(HOME)/Mistral-7B-v0.1-hf-4bit-mlx
--prompt "I ponder cheese."
--max-tokens 50
```

Then cmd-r to run.

### Running (Command Line)

`llm-tool` can also be run from the command line if built from Xcode, but 
the `DYLD_FRAMEWORK_PATH` must be set so that the frameworks and bundles can be found:

- [MLX troubleshooting](https://ml-explore.github.io/mlx-swift/MLX/documentation/mlx/troubleshooting)

The easiest way to do this is drag the Products/llm-tool into Terminal to get the path:

```
DYLD_FRAMEWORK_PATH=~/Library/Developer/Xcode/DerivedData/mlx-examples-swift-ceuohnhzsownvsbbleukxoksddja/Build/Products/Debug ~/Library/Developer/Xcode/DerivedData/mlx-examples-swift-ceuohnhzsownvsbbleukxoksddja/Build/Products/Debug/llm-tool --model ~/Mistral-7B-v0.1-hf-4bit-mlx
```

