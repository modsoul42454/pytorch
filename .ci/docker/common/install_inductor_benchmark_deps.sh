set -ex

source "$(dirname "${BASH_SOURCE[0]}")/common_utils.sh"

function install_huggingface() {
  local version
  version=$(get_pinned_commit huggingface)
  pip_install pandas
  pip_install scipy
  pip_install "transformers==${version}"
}

function install_timm() {
  local commit
  commit=$(get_pinned_commit timm)
  pip_install pandas
  pip_install scipy
  pip_install "git+https://github.com/rwightman/pytorch-image-models@${commit}"
}

function checkout_install_torchbench() {
  local commit
  commit=$(get_pinned_commit torchbench)
  git clone https://github.com/pytorch/benchmark torchbench
  pushd torchbench
  git checkout "$commit"

  if [ "$1" ]; then
    as_jenkins python install.py --continue_on_fail models "$@"
  else
    # Occasionally the installation may fail on one model but it is ok to continue
    # to install and test other models
    as_jenkins python install.py --continue_on_fail
  fi
  popd
}

function install_torchaudio() {
  local commit
  commit=$(get_pinned_commit audio)
  if [[ "$1" == "cuda" ]]; then
    # TODO: This is better to be passed as a parameter from _linux-test workflow
    # so that it can be consistent with what is set in build
    TORCH_CUDA_ARCH_LIST="8.0;8.6" pip_install --no-use-pep517 --user "git+https://github.com/pytorch/audio.git@${commit}"
  else
    pip_install --no-use-pep517 --user "git+https://github.com/pytorch/audio.git@${commit}"
  fi

}

function install_torchtext() {
  local data_commit
  local text_commit
  data_commit=$(get_pinned_commit data)
  text_commit=$(get_pinned_commit text)
  pip_install --no-use-pep517 --user "git+https://github.com/pytorch/data.git@${data_commit}"
  pip_install --no-use-pep517 --user "git+https://github.com/pytorch/text.git@${text_commit}"
}

function install_torchvision() {
  local commit
  commit=$(get_pinned_commit vision)
  pip_install --no-use-pep517 --user "git+https://github.com/pytorch/vision.git@${commit}"
}

install_huggingface
install_timm
# install_torchaudio
# install_torchtext
# install_torchvision
# checkout_install_torchbench

if [ -n "${CONDA_CMAKE}" ]; then
  # Keep the current cmake and numpy version here, so we can reinstall them later
  NUMPY_VERSION=$(get_conda_version numpy)
fi

pip_uninstall "torch"

# if [ -n "${CONDA_CMAKE}" ]; then
#   # TODO: This is to make sure that the same cmake and numpy version from install conda
#   # script is used. Without this step, the newer cmake version (3.25.2) downloaded by
#   # triton build step via pip will fail to detect conda MKL. Once that issue is fixed,
#   # this can be removed.
#   #
#   # The correct numpy version also needs to be set here because conda claims that it
#   # causes inconsistent environment.  Without this, conda will attempt to install the
#   # latest numpy version, which fails ASAN tests with the following import error: Numba
#   # needs NumPy 1.20 or less.
#   conda_reinstall cmake="${CMAKE_VERSION}"
#   conda_reinstall numpy="${NUMPY_VERSION}"
# fi