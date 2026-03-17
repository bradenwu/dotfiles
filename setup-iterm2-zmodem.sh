#!/bin/bash
set -e

echo "🔧 [setup-iterm2-zmodem] Start configuring ZModem for iTerm2..."

# 1️⃣ 检查 Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo "⚠️ Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew is already installed."
fi

# 2️⃣ 安装 lrzsz
if ! brew list lrzsz >/dev/null 2>&1; then
    echo "📦 Installing lrzsz..."
    brew install lrzsz
else
    echo "✅ lrzsz is already installed."
fi

# 3️⃣ 创建脚本目录
mkdir -p ~/.iterm2

# 4️⃣ 创建发送脚本
cat > ~/.iterm2/iterm2-send-zmodem.sh <<'EOF'
#!/bin/bash
# ZModem send script for iTerm2
/usr/local/bin/lsz --zmodem --escape --binary --overwrite "$@"
EOF

# 5️⃣ 创建接收脚本
cat > ~/.iterm2/iterm2-recv-zmodem.sh <<'EOF'
#!/bin/bash
# ZModem receive script for iTerm2
/usr/local/bin/lrz --zmodem --escape --binary --overwrite "$@"
EOF

chmod +x ~/.iterm2/iterm2-*.sh

echo "✅ Created ZModem scripts in ~/.iterm2/"
echo "   - ~/.iterm2/iterm2-send-zmodem.sh"
echo "   - ~/.iterm2/iterm2-recv-zmodem.sh"

# 6️⃣ 输出 Trigger 配置提示
echo
echo "⚙️  Next Step: Configure iTerm2 Triggers manually (only once)"
echo
echo "   1. 打开 iTerm2 → Preferences → Profiles → Advanced → Triggers → Edit"
echo "   2. 添加以下两条规则："
echo
echo "      ┌──────────────────────────────────────────────────────────┐"
echo "      │ Regular Expression            │ Action           │ Parameter                  │"
echo "      │──────────────────────────────────────────────────────────│"
echo "      │ rz waiting to receive.*B0100  │ Run Silent Coprocess │ ~/.iterm2/iterm2-recv-zmodem.sh │"
echo "      │ \\*\\*B00000000000000          │ Run Silent Coprocess │ ~/.iterm2/iterm2-send-zmodem.sh │"
echo "      └──────────────────────────────────────────────────────────┘"
echo
echo "   ✅ 完成后，重启 iTerm2 即可生效。"

# 7️⃣ 测试命令提示
echo
echo "🚀 Test:"
echo "   SSH 登录到远程服务器（已安装 lrzsz），然后执行："
echo "     ➜ rz    ← 上传文件到服务器"
echo "     ➜ sz <filename> ← 下载文件到本地"
echo
echo "✅ Setup completed successfully!"
