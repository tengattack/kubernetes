# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("//build:platforms.bzl", "SERVER_PLATFORMS")
load("//build:workspace_mirror.bzl", "mirror")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@io_bazel_rules_docker//container:container.bzl", "container_pull")

CNI_VERSION = "0.7.5"
_CNI_TARBALL_ARCH_SHA256 = {
    "amd64": "3ca15c0a18ee830520cf3a95408be826cbd255a1535a38e0be9608b25ad8bf64",
    "arm": "0eb4a528b5b2e4ce23ebc96e41b2f5280d5a64d41eec8dd8b16c3d66aaa0f6b8",
    "arm64": "7fec91af78e9548df306f0ec43bea527c8c10cc3a9682c33e971c8522a7fcded",
    "ppc64le": "9164a26ed8dd398b2fe3b15d9d456271dfa59aa537528d10572ea9fa2cef7679",
    "s390x": "415cdcf02c65c22f5b7e55b0ab61208a10f2b95a0c8310176c771d07a9f448cf",
}

CRI_TOOLS_VERSION = "1.14.0"
_CRI_TARBALL_ARCH_SHA256 = {
    "amd64": "483c90a9fe679590df4332ba807991c49232e8cd326c307c575ecef7fe22327b",
    "arm": "9910cecfd6558239ba015323066c7233d8371af359b9ddd0b2a35d5223bcf945",
    "arm64": "f76b3d00a272c8d210e9a45f77d07d3770bee310d99c4fd9a72d6f55278882e5",
    "ppc64le": "1e2cd11a1e025ed9755521cf13bb1bda986afa0052597a9bb44d31e62583413b",
    "s390x": "8b7b5749cba88ef337997ae90aa04380e3cab2c040b44b505b2fcd691c4935e4",
}

ETCD_VERSION = "3.3.10"
_ETCD_TARBALL_ARCH_SHA256 = {
    "amd64": "1620a59150ec0a0124a65540e23891243feb2d9a628092fb1edcc23974724a45",
    "arm64": "5ec97b0b872adce275b8130d19db314f7f2b803aeb24c4aae17a19e2d66853c4",
    "ppc64le": "148fe96f0ec1813c5db9916199e96a913174304546bc8447a2d2f9fee4b8f6c2",
}

# Dependencies needed for a Kubernetes "release", e.g. building docker images,
# debs, RPMs, or tarballs.
def release_dependencies():
    cni_tarballs()
    cri_tarballs()
    debian_image_dependencies()
    etcd_tarballs()

def cni_tarballs():
    for arch, sha in _CNI_TARBALL_ARCH_SHA256.items():
        http_file(
            name = "kubernetes_cni_%s" % arch,
            downloaded_file_path = "kubernetes_cni.tgz",
            sha256 = sha,
            urls = mirror("https://storage.googleapis.com/kubernetes-release/network-plugins/cni-plugins-%s-v%s.tgz" % (arch, CNI_VERSION)),
        )

def cri_tarballs():
    for arch, sha in _CRI_TARBALL_ARCH_SHA256.items():
        http_file(
            name = "cri_tools_%s" % arch,
            downloaded_file_path = "cri_tools.tgz",
            sha256 = sha,
            urls = mirror("https://github.com/kubernetes-incubator/cri-tools/releases/download/v%s/crictl-v%s-linux-%s.tar.gz" % (CRI_TOOLS_VERSION, CRI_TOOLS_VERSION, arch)),
        )

# Use go get -u github.com/estesp/manifest-tool to find these values
_DEBIAN_BASE_DIGEST = {
    "manifest": "sha256:ebda8587ec0f49eb88ee3a608ef018484908cbc5aa32556a0d78356088c185d4",
    "amd64": "sha256:d7be39e143d4e6677a28c81c0a84868b40800fc979dea1848bb19d526668a00c",
    "arm": "sha256:fc731da13b0bc9013b85a86b583fc92e50869b5bc8e7aa6ca730ec0240954c7d",
    "arm64": "sha256:12502c3eed050fa9b6d5fe353a44bfc5f437dc325c8912b1a48dcc180df36f1e",
    "ppc64le": "sha256:4277aa59b63c5a1369e6d84a295ecc4ffa08985dcf114de9f7b6de1af4fcbc86",
    "s390x": "sha256:78ef2a6b017539379c1654b4e52ba8519bfec821c62d0b3a1dbd15104b711e21",
}

_DEBIAN_IPTABLES_DIGEST = {
    "manifest": "sha256:d1cd487e89fb4cba853cd3a948a6e9016faf66f2a7bb53cb1ac6b6c9cb58f5ed",
    "amd64": "sha256:852d3c569932059bcab3a52cb6105c432d85b4b7bbd5fc93153b78010e34a783",
    "arm": "sha256:c10f01b414a7cd4b2f3e26e152c90c64a1e781d99f83a6809764cf74ecbc46c3",
    "arm64": "sha256:5725e6fde13a6405cf800e22846ebd2bde24b0860f1dc3f6f5f256f03cfa85bd",
    "ppc64le": "sha256:b6d6e56a0c34c0393dcba0d5faaa531b92e5876114c5ab5a90e82e4889724c5a",
    "s390x": "sha256:39e67e9bf25d67fe35bd9dcb25367277e5967368e02f2741e0efd4ce8874db14",
}

_DEBIAN_HYPERKUBE_BASE_DIGEST = {
    "manifest": "sha256:8cabe02be6e86685d8860b7ace7c7addc9591a339728703027a4854677f1c772",
    "amd64": "sha256:5d4ea2fb5fbe9a9a9da74f67cf2faefc881968bc39f2ac5d62d9167e575812a1",
    "arm": "sha256:73260814af61522ff6aa48291df457d3bb0a91c4bf72e7cfa51fbaf03eb65fae",
    "arm64": "sha256:78eeb1a31eef7c16f954444d64636d939d89307e752964ad6d9d06966c722da3",
    "ppc64le": "sha256:92857d647abe8d9c7b4d7160cd5699112afc12fde369082a8ed00688b17928a9",
    "s390x": "sha256:c11d74fa0538c67238576c247bfaddf95ebaa90cd03cb4d2f2ac3c6ebe0441e2",
}

def _digest(d, arch):
    if arch not in d:
        print("WARNING: %s not found in %r" % (arch, d))
        return d["manifest"]
    return d[arch]

def debian_image_dependencies():
    for arch in SERVER_PLATFORMS["linux"]:
        container_pull(
            name = "debian-base-" + arch,
            architecture = arch,
            digest = _digest(_DEBIAN_BASE_DIGEST, arch),
            registry = "k8s.gcr.io",
            repository = "debian-base",
            tag = "v2.0.0",  # ignored, but kept here for documentation
        )

        container_pull(
            name = "debian-iptables-" + arch,
            architecture = arch,
            digest = _digest(_DEBIAN_IPTABLES_DIGEST, arch),
            registry = "k8s.gcr.io",
            repository = "debian-iptables",
            tag = "v12.0.1",  # ignored, but kept here for documentation
        )

        container_pull(
            name = "debian-hyperkube-base-" + arch,
            architecture = arch,
            digest = _digest(_DEBIAN_HYPERKUBE_BASE_DIGEST, arch),
            registry = "k8s.gcr.io",
            repository = "debian-hyperkube-base",
            tag = "0.12.1",  # ignored, but kept here for documentation
        )

def etcd_tarballs():
    for arch, sha in _ETCD_TARBALL_ARCH_SHA256.items():
        http_archive(
            name = "com_coreos_etcd_%s" % arch,
            build_file = "@//third_party:etcd.BUILD",
            sha256 = sha,
            strip_prefix = "etcd-v%s-linux-%s" % (ETCD_VERSION, arch),
            urls = mirror("https://github.com/coreos/etcd/releases/download/v%s/etcd-v%s-linux-%s.tar.gz" % (ETCD_VERSION, ETCD_VERSION, arch)),
        )
