#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

FEEDS_PATH="./feeds"
PACKAGE_PATH="./package"

#修补命令统一入口：FIX <名称> <守卫目录> <命令...>
#守卫目录不存在时直接跳过，保证在 bash -e 下不中断
FIX() {
	local NAME=$1
	local GUARD=$2
	shift 2

	[ -d "$GUARD" ] || return 0

	echo " "
	if "$@"; then
		echo "$NAME has been fixed!"
	else
		echo "$NAME fix failed; continuing!"
	fi
}

#修改argon主题字体和颜色
FIX "theme-argon" "$PACKAGE_PATH/luci-theme-argon" sed -i \
	"s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" \
	"$PACKAGE_PATH/luci-theme-argon/luci-app-argon-config/root/etc/config/argon"

#修改aurora菜单式样
FIX "theme-aurora" "$PACKAGE_PATH/luci-app-aurora-config" find \
	"$PACKAGE_PATH/luci-app-aurora-config/root/usr/share/aurora/" -type f -name '*.template' -exec sed -i \
	"s/nav_type '.*'/nav_type 'dropdown'/g; s/struct_radius_base '.*'/struct_radius_base '0.125rem'/g" {} +

#修改vantage进度条标签字体（anothaDev/luci-theme-vantage#52）
FIX "theme-vantage" "$PACKAGE_PATH/luci-theme-vantage" sed -i \
	-e '/^\/\* progress bars: thin track/,$ { /^\.cbi-progressbar::before {/,/^}/ { s/^[[:space:]]*font: 500 var(--fs-micro)\/1\.2 var(--mono);/\tfont: inherit; line-height: normal;/; } }' \
	"$PACKAGE_PATH/luci-theme-vantage/luci-theme-vantage/htdocs/luci-static/vantage/vantage.css"

#修改mini-diskmanager菜单位置
FIX "mini-diskmanager" "$PACKAGE_PATH/luci-app-mini-diskmanager" sed -i "s/services/system/g" \
	"$PACKAGE_PATH/luci-app-mini-diskmanager/luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json"

#修改natmapt菜单位置
FIX "natmapt" "$PACKAGE_PATH/luci-app-natmapt" sed -i "s/network/services/g" \
	"$PACKAGE_PATH/luci-app-natmapt/root/usr/share/luci/menu.d/luci-app-natmap.json"
	
# ==========================================
# 1. 修复框架自带的权限报错
# ==========================================
chmod +x /home/runner/work/*/*/.github/scripts/collect-build-reports.sh 2>/dev/null || true

# ==========================================
# 2. 磊科 N60 Pro 硬改适配：2G 内存 + 506.5M UBI
# ==========================================
DTS_FILE="target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts"

if [ -f "$DTS_FILE" ]; then
    echo "开始修改 N60 Pro 设备树..."
    # 修改内存为 2GB (0x80000000)
    sed -i 's/reg = <0 0x40000000 0 0x20000000>;/reg = <0 0x40000000 0 0x80000000>;/' "$DTS_FILE"
    # 修改 UBI 分区大小为 506.5M (0x1FA80000)
    sed -i '/label = "ubi"/ { n; s/reg = <[^>]*>;/reg = <0x580000 0x1FA80000>;/ }' "$DTS_FILE"
    echo "✅ N60 Pro DTS 修改完成（2G RAM + 506.5M UBI）"
else
    echo "❌ 警告：未找到 DTS 文件，请检查源码路径！"
fi

# ==========================================
# 3. 强制写入参数 (双重保险，防止被编译系统重新覆盖勾选)
# ==========================================
echo "CONFIG_KERNEL_DEBUG_INFO=y" >> .config
echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> .config
echo "CONFIG_KERNEL_DEBUG_INFO_REDUCED=n" >> .config
echo "CONFIG_DWARVES=y" >> .config

echo "# CONFIG_PACKAGE_luci-app-samba4 is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-ksmbd is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-wolultra is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-gecoosac is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-homeproxy is not set" >> .config

# ==========================================
# 4. 拉取 Honk 源码
# ==========================================
echo "正在拉取 honk 源码..."
git clone --depth=1 https://github.com/kenzok8/openwrt-honk.git package/openwrt-honk
