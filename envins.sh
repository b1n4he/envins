#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            echo "ubuntu"
        else
            error "不支持的操作系统: $ID"
        fi
    else
        error "无法检测操作系统"
    fi
}

# 检查并安装包管理器
install_package_manager() {
    local os=$(detect_os)
    
    if [[ "$os" == "macos" ]]; then
        
        if ! command -v brew &> /dev/null; then
            info "Homebrew 未安装，正在安装..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Homebrew 安装失败"
            info "Homebrew 安装完成"
        else
            info "Homebrew 已安装，正在更新..."
            brew update
        fi
    elif [[ "$os" == "ubuntu" ]]; then
        if [ "$EUID" -ne 0 ]; then
            error "请以 root 权限运行此脚本 (sudo)"
        fi
        info "更新 apt 包列表..."
        apt-get update || error "apt 更新失败"
    fi
}

# 安装系统依赖
install_dependencies() {
    local os=$(detect_os)
    info "正在安装系统依赖..."
    
    if [[ "$os" == "macos" ]]; then
        # Mac 依赖安装
        brew install \
            curl \
            wget \
            git \
            make \
            gcc \
            automake \
            autoconf \
            tmux \
            htop \
            pkg-config \
            openssl \
            jq \
            lz4 \
            ncdu \
            unzip || error "依赖安装失败"
    elif [[ "$os" == "ubuntu" ]]; then
        # Ubuntu 依赖安装
        apt-get install -y \
            curl \
            wget \
            git \
            build-essential \
            make \
            gcc \
            automake \
            autoconf \
            tmux \
            htop \
            pkg-config \
            libssl-dev \
            jq \
            lz4 \
            clang \
            ncdu \
            unzip || error "依赖安装失败"
    fi
    
    info "基础依赖安装完成"
}

# 安装 Docker
install_docker() {
    local os=$(detect_os)
    
    if [[ "$os" == "macos" ]]; then
        if ! command -v docker &> /dev/null; then
            info "Docker 未安装，正在安装..."
            brew install --cask docker || error "Docker 安装失败"
            info "Docker 安装完成"
        else
            info "Docker 已安装，检查更新..."
            brew upgrade --cask docker
        fi
        # 启动 Docker
        open -a Docker || error "Docker 启动失败"
    elif [[ "$os" == "ubuntu" ]]; then
        if ! command -v docker &> /dev/null; then
            info "Docker 未安装，正在安装..."
            apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                software-properties-common || error "Docker 依赖安装失败"
            
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - || error "Docker GPG 密钥添加失败"
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || error "Docker 仓库添加失败"
            
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io || error "Docker 安装失败"
            info "Docker 安装完成"
        else
            info "Docker 已安装，检查更新..."
            apt-get install -y docker-ce docker-ce-cli containerd.io
        fi
        
        # 启动 Docker 服务
        systemctl start docker || error "Docker 服务启动失败"
        systemctl enable docker || error "Docker 服务启用失败"
    fi
    
    info "Docker 已启动"
}

# 主函数
main() {
    info "开始安装环境..."
    
    # 检查并安装包管理器
    install_package_manager
    
    # 安装系统依赖
    install_dependencies
    
    # 安装 Docker
    install_docker
    
    info "环境安装完成！"
    if [[ "$(detect_os)" == "macos" ]]; then
        info "请确保 Docker Desktop 已经启动并运行"
    fi
}

# 捕获 Ctrl+C
trap 'error "安装被用户中断"' INT

# 运行主函数
main 
