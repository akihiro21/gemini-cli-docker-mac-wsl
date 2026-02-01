#!/bin/bash
# multi-agent-manager-gemini 起動スクリプト（毎日の起動用）
# Daily Deployment Script for Multi-Agent Orchestration System
#
# 使用方法:
#   ./multi-agent-start.sh           # 全エージェント起動（通常）
#   ./multi-agent-start.sh -s        # セットアップのみ（Gemini起動なし）
#   ./multi-agent-start.sh -h        # ヘルプ表示

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 言語設定を読み取り（デフォルト: ja）
LANG_SETTING="ja"
if [ -f "./config/settings.yaml" ]; then
    LANG_SETTING=$(grep "^language:" ./config/settings.yaml 2>/dev/null | awk '{print $2}' || echo "ja")
fi

# シェル設定を読み取り（デフォルト: bash）
SHELL_SETTING="bash"
if [ -f "./config/settings.yaml" ]; then
    SHELL_SETTING=$(grep "^shell:" ./config/settings.yaml 2>/dev/null | awk '{print $2}' || echo "bash")
fi

# 色付きログ関数
log_info() {
    echo -e "\033[1;33m【情報】\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m【成功】\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m【エラー】\033[0m $1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# プロンプト生成関数（bash/zsh対応）
# ───────────────────────────────────────────────────────────────────────────────
# 使用法: generate_prompt "ラベル" "色" "シェル"
# 色: red, green, blue, magenta, cyan, yellow
# ═══════════════════════════════════════════════════════════════════════════════
generate_prompt() {
    local label="$1"
    local color="$2"
    local shell_type="$3"

    if [ "$shell_type" == "zsh" ]; then
        # zsh用: %F{color}%B...%b%f 形式
        echo "(%F{${color}}%B${label}%b%f) %F{green}%B%~%b%f%# "
    else
        # bash用: \[\033[...m\] 形式
        local color_code
        case "$color" in
            red)     color_code="1;31" ;;
            green)   color_code="1;32" ;;
            yellow)  color_code="1;33" ;;
            blue)    color_code="1;34" ;;
            magenta) color_code="1;35" ;;
            cyan)    color_code="1;36" ;;
            *)       color_code="1;37" ;;  # white (default)
        esac
        echo "(\[\033[${color_code}m\]${label}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ "
    fi
}

# Gemini CLIの準備完了を待つ関数
wait_for_gemini_ready() {
    local target_pane="$1"
    local timeout_sec=60
    log_info "  └─ ${target_pane} の Gemini CLI 準備完了を待機中（最大${timeout_sec}秒）..."
    for i in $(seq 1 $timeout_sec); do
        if tmux capture-pane -t "$target_pane" -p | grep -q "YOLO mode"; then
            log_info "  └─ ${target_pane} の Gemini CLI 起動確認完了（${i}秒）"
            return 0
        fi
        sleep 3
    done
    log_error "  └─ エラー: ${target_pane} の Gemini CLI が ${timeout_sec}秒以内に準備できませんでした。"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# オプション解析
# ═══════════════════════════════════════════════════════════════════════════════
SETUP_ONLY=false
OPEN_TERMINAL=false
SHELL_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--setup-only)
            SETUP_ONLY=true
            shift
            ;;
        -t|--terminal)
            OPEN_TERMINAL=true
            shift
            ;;
        -shell|--shell)
            if [[ -n "$2" && "$2" != -* ]]; then
                SHELL_OVERRIDE="$2"
                shift 2
            else
                echo "エラー: -shell オプションには bash または zsh を指定してください"
                exit 1
            fi
            ;;
        -h|--help)
            echo ""
            echo "multi-agent-manager-gemini 起動スクリプト"
            echo ""
            echo "使用方法: ./multi-agent-start.sh [オプション]"
            echo ""
            echo "オプション:"
            echo "  -s, --setup-only    tmuxセッションのセットアップのみ（Gemini起動なし）"
            echo "  -t, --terminal      Windows Terminal で新しいタブを開く"
            echo "                      未指定時は config/settings.yaml の設定を使用"
            echo "  -h, --help          このヘルプを表示"
            echo ""
            echo "例:"
            echo "  ./multi-agent-start.sh              # 全エージェント起動（通常の起動）"
            echo "  ./multi-agent-start.sh -s           # セットアップのみ（手動でGemini起動）"
            echo "  ./multi-agent-start.sh -t           # 全エージェント起動 + ターミナルタブ展開"
            echo "  ./multi-agent-start.sh -shell bash  # bash用プロンプトで起動"
            echo "  ./multi-agent-start.sh -shell zsh   # zsh用プロンプトで起動"
            echo ""
            echo "エイリアス:"
            echo "  csst  → cd \"$(pwd)\" && ./multi-agent-start.sh"
            echo "  css   → tmux attach-session -t manager"
            echo "  csm   → tmux attach-session -t multiagent"
            echo ""
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            echo "./multi-agent-start.sh -h でヘルプを表示"
            exit 1
            ;;
    esac
done

# シェル設定のオーバーライド（コマンドラインオプション優先）
if [ -n "$SHELL_OVERRIDE" ]; then
    if [[ "$SHELL_OVERRIDE" == "bash" || "$SHELL_OVERRIDE" == "zsh" ]]; then
        SHELL_SETTING="$SHELL_OVERRIDE"
    else
        echo "エラー: -shell オプションには bash または zsh を指定してください（指定値: $SHELL_OVERRIDE）"
        exit 1
    fi
fi

    # ═══════════════════════════════════════════════════════════════════════════════
    # バナー表示関数
    # ───────────────────────────────────────────────────────────────────────────────
    show_battle_cry() {
        clear
    # タイトルメッセージ
    echo ""
    echo -e "\033[1;31m======================================================================================\033[0m"
    echo -e "\033[1;31m|                        \033[1;37mマルチエージェントシステム起動                  \033[1;31m|\033[0m"
    echo -e "\033[1;31m======================================================================================\033[0m"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # システム情報
    # ═══════════════════════════════════════════════════════════════════════════
    echo -e "\033[1;33m  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
    echo -e "\033[1;33m  ┃\033[0m  \033[1;37m マルチエージェント統率システム\033[0m                                             \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m                                                                           \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m    \033[1;35mManager\033[0m: プロジェクト統括    \033[1;31mLeader\033[0m: タスク管理    \033[1;34mWorker\033[0m: 実働部隊×8      \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"
    echo ""
}

# バナー表示実行
show_battle_cry

echo -e "  \033[1;33mシステム起動を開始します\033[0m"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: 既存セッションクリーンアップ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "🧹 既存のセッションを終了中..."
tmux kill-session -t multiagent 2>/dev/null && log_info "  └─ multiagentセッション、終了完了" || log_info "  └─ multiagentセッションは存在せず"
tmux kill-session -t manager 2>/dev/null && log_info "  └─ managerセッション、終了完了" || log_info "  └─ managerセッションは存在せず"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1.5: 前回記録のバックアップ（内容がある場合のみ）
# ═══════════════════════════════════════════════════════════════════════════════
BACKUP_DIR="./logs/backup_$(date '+%Y%m%d_%H%M%S')"
NEED_BACKUP=false

if [ -f "./dashboard.md" ]; then
    if grep -q "cmd_" "./dashboard.md" 2>/dev/null; then
        NEED_BACKUP=true
    fi
fi

if [ "$NEED_BACKUP" = true ]; then
    mkdir -p "$BACKUP_DIR" || true
    cp "./dashboard.md" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "./queue/reports" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "./queue/tasks" "$BACKUP_DIR/" 2>/dev/null || true
    cp "./queue/manager_to_leader.yaml" "$BACKUP_DIR/" 2>/dev/null || true
    log_info "📦 前回の記録をバックアップ: $BACKUP_DIR"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: 報告ファイルリセット
# ═══════════════════════════════════════════════════════════════════════════════
log_info "📜 前回のログデータをクリア中..."

# queue ディレクトリが存在しない場合は作成
[ -d ./queue/reports ] || mkdir -p ./queue/reports
[ -d ./queue/tasks ] || mkdir -p ./queue/tasks

# Workerタスクファイルリセット
for i in {1..3}; do
    cat > ./queue/tasks/worker${i}.yaml << EOF
# Worker${i}専用タスクファイル
task:
  task_id: null
  parent_cmd: null
  description: null
  target_path: null
  status: idle
  timestamp: ""
EOF
done

# Workerレポートファイルリセット
for i in {1..3}; do
    cat > ./queue/reports/worker${i}_report.yaml << EOF
worker_id: worker${i}
task_id: null
timestamp: ""
status: idle
result: null
EOF
done

# キューファイルリセット
cat > ./queue/manager_to_leader.yaml << 'EOF'
queue: []
EOF

# Leader -> Worker 用のキューファイルを生成
cat > ./queue/leader_to_worker.yaml << EOF
assignments:
  worker1:
    task_id: null
    description: null
    target_path: null
    status: idle
  worker2:
    task_id: null
    description: null
    target_path: null
    status: idle
  worker3:
    task_id: null
    description: null
    target_path: null
    status: idle
EOF


log_success "✅ クリア完了"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: ダッシュボード初期化
# ═══════════════════════════════════════════════════════════════════════════════
log_info "📊 ダッシュボードを初期化中..."
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# 日本語のみのdashboard.mdを生成
cat > ./dashboard.md << EOF
# 📊 状況報告
最終更新: ${TIMESTAMP}

## 🚨 要対応 - ユーザーの判断をお待ちしております
なし

## 🔄 進行中 - 現在進行中のタスク
なし

## ✅ 本日の成果
| 時刻 | タスク | 任務 | 結果 |
|------|--------|------|------|

## 🎯 スキル化候補 - 承認待ち
なし

## 🛠️ 生成されたスキル
なし

## ⏸️ 待機中
なし

## ❓ 質問事項
なし
EOF

log_success "  └─ ダッシュボード初期化完了 (言語: $LANG_SETTING, シェル: $SHELL_SETTING)"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: multiagentセッション作成（4ペイン：Leader + Worker1-3）
# ═══════════════════════════════════════════════════════════════════════════════
# tmux の存在確認
if ! command -v tmux &> /dev/null; then
    echo ""
    echo "  ╔════════════════════════════════════════════════════════╗"
    echo "  ║  [ERROR] tmux not found!                               ║"
    echo "  ║  tmux が見つかりません                                 ║"
    echo "  ╠════════════════════════════════════════════════════════╣"
    echo "  ║  Run first_setup.sh first:                             ║"
    echo "  ║  まず first_setup.sh を実行してください:               ║"
    echo "  ║     ./first_setup.sh                                   ║"
    echo "  ╚════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

log_info "Leader・Workerセッションを構築中（4ペイン：Leader + Worker1-3）..."

# 最初のペイン作成
if ! tmux new-session -d -s multiagent -n "agents" 2>/dev/null; then
    echo ""
    echo "  ╔════════════════════════════════════════════════════════════╗"
    echo "  ║  [ERROR] Failed to create tmux session 'multiagent'        ║"
    echo "  ║  tmux セッション 'multiagent' の作成に失敗しました         ║"
    echo "  ╠════════════════════════════════════════════════════════════╣"
    echo "  ║  An existing session may be running.                       ║"
    echo "  ║  既存セッションが残っている可能性があります                ║"
    echo "  ║                                                            ║"
    echo "  ║  Check: tmux ls                                            ║"
    echo "  ║  Kill:  tmux kill-session -t multiagent                    ║"
    echo "  ╚════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

# 2x2グリッド作成（合計4ペイン）
# 最初に2列に分割
tmux split-window -h -t "multiagent:0"

# 各列を3行に分割
tmux select-pane -t "multiagent:0"
tmux split-window -v
tmux split-window -v

log_info "pain完了"

# ペインタイトル設定（0: Leader, 1-3: Worker1-3）
PANE_TITLES=("Leader" "Worker1" "Worker2" "Worker3")
# 色設定（Leader: red, Worker: blue）
PANE_COLORS=("red" "blue" "blue" "blue")

for i in {0..3}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    PROMPT_STR=$(generate_prompt "${PANE_TITLES[$i]}" "${PANE_COLORS[$i]}" "$SHELL_SETTING")
    tmux send-keys -t "multiagent:0.$i" "cd \"$(pwd)\" && export PS1='${PROMPT_STR}' && clear" Enter
done

log_success "  └─ Leader・Workerセッション、構築完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: managerセッション作成（1ペイン）
# ═══════════════════════════════════════════════════════════════════════════════
log_info "Managerセッションを構築中..."
if ! tmux new-session -d -s manager 2>/dev/null; then
    echo ""
    echo "  ╔════════════════════════════════════════════════════════════╗"
    echo "  ║  [ERROR] Failed to create tmux session 'manager'           ║"
    echo "  ║  tmux セッション 'manager' の作成に失敗しました            ║"
    echo "  ╠════════════════════════════════════════════════════════════╣"
    echo "  ║  An existing session may be running.                       ║"
    echo "  ║  既存セッションが残っている可能性があります                ║"
    echo "  ║                                                            ║"
    echo "  ║  Check: tmux ls                                            ║"
    echo "  ║  Kill:  tmux kill-session -t manager                       ║"
    echo "  ╚════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi
MANAGER_PROMPT=$(generate_prompt "Manager" "magenta" "$SHELL_SETTING")
tmux send-keys -t manager "cd \"$(pwd)\" && export PS1='${MANAGER_PROMPT}' && clear" Enter
tmux select-pane -t manager:0.0 -P 'bg=#002b36'  # Managerの Solarized Dark

log_success "  └─ Managerセッション、構築完了"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: Gemini CLI 起動（--setup-only でスキップ）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ]; then
    # Gemini CLI の存在チェック
    if ! command -v node &> /dev/null || [ ! -f /app/gemini-cli-src/bundle/gemini.js ]; then
        log_info "⚠️  Gemini CLIが見つかりません"
        echo "  Gemini CLIがインストールされているか確認してください。"
        echo "  またはfirst_setup.shを実行してください。"
        echo "    ./first_setup.sh"
        exit 1
    fi

    log_info "Gemini CLI エージェントを起動中..."

    # Manager
    tmux send-keys -t manager "node /app/gemini-cli-src/bundle/gemini.js --yolo"
    tmux send-keys -t manager Enter
    log_info "manager配備完了"
    
    sleep 1

    # Leader + Worker（4ペイン）
    for i in {0..3}; do
        tmux send-keys -t "multiagent:0.$i" "node /app/gemini-cli-src/bundle/gemini.js --yolo"
        tmux send-keys -t "multiagent:0.$i" Enter
    done
    log_info "Leader, worker配備完了"

    log_success "✅ 全Agent Gemini CLI 起動完了"
    echo ""
    log_info "Gemini CLI の起動を待機中（最大180秒）..."

    # ═══════════════════════════════════════════════════════════════════════════════
    # STEP 6.5: 各エージェントに指示書を伝達する
    # ═══════════════════════════════════════════════════════════════════════════════
    log_info "📜 各エージェントに指示書を読み込ませています..."
    echo ""

    log_info " 全エージェントのGemini CLI起動を確認中..."
    for i in {1..180}; do
      ALL_READY=true
      
      # Managerの確認
      if ! tmux capture-pane -t manager -p 2>/dev/null | grep -q "Type your message or @path/to/file"; then
        ALL_READY=false
      else
        # Leader・Workerの確認 (0..3)
        for p in {0..3}; do
          if ! tmux capture-pane -t "multiagent:0.$p" -p 2>/dev/null | grep -q "Type your message or @path/to/file"; then
            ALL_READY=false
            break
          fi
        done
      fi

      if [ "$ALL_READY" = true ]; then
        log_info " └─ 全エージェントの Gemini CLI 起動確認完了（${i}秒）"
        break
      fi
      sleep 1
    done

    sleep 5

    # ═══════════════════════════════════════════════════════════════════════════════
    # STEP 6.5: 各エージェントに指示書を伝達する
    # ═══════════════════════════════════════════════════════════════════════════════
    log_info "📜 各エージェントに指示書を読み込ませています..."
    echo ""

    # Managerに指示書を読み込ませる
    log_info "  └─ Managerに指示書を伝達中..."
    tmux send-keys -t manager "instructions/manager.md を読んで役割を理解してください。"
    sleep 0.5
    tmux send-keys -t manager C-m

    sleep 1
    # Leaderに指示書を読み込ませる
    log_info "  └─ Leaderに指示書を伝達中..."
    tmux send-keys -t "multiagent:0.0" "instructions/leader.md を読んで役割を理解してください。"
    sleep 0.5
    tmux send-keys -t "multiagent:0.0" C-m

    sleep 1
    # Workerに指示書を読み込ませる（1-3）
    log_info "  └─ Workerに指示書を伝達中..."
    for i in {1..3}; do
        tmux send-keys -t "multiagent:0.$i" "instructions/worker.md を読んで役割を理解してください。あなたはWorker${i}です。"
        sleep 0.5
        tmux send-keys -t "multiagent:0.$i" C-m
	sleep 5
    done

    log_success "✅ 全エージェントへの指示書伝達が完了しました"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: 環境確認・完了メッセージ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "🔍 現在のセッション構成を確認中..."
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  📺 Tmuxセッション (Sessions)                                  │"
echo "  └──────────────────────────────────────────────────────────┘"
tmux list-sessions | sed 's/^/     /'
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  📋 セッション構成 (Formation)                                   │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "     【managerセッション】Managerセッション"
echo "     ┌─────────────────────────────┐"
echo "     │  Pane 0: Manager (MANAGER)  │  ← プロジェクト統括エージェント"
echo "     └─────────────────────────────┘"
echo ""
echo "     【multiagentセッション】Leader・Workerセッション（3x3 = 9ペイン）"
echo "     ┌─────────┬─────────┐"
echo "     │ Leader  │ Worker2 │"
echo "     │(Leader) │(Worker2)│"
echo "     ├─────────┼─────────┤"
echo "     │ Worker1 │ Worker3 │"
echo "     │(Worker1)│(Worker3)│"
echo "     └─────────┸─────────┘"
echo ""

echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  起動準備完了！                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

if [ "$SETUP_ONLY" = true ]; then
    echo "  ⚠️  セットアップのみモード: Gemini CLIは未起動です"
    echo ""
    echo "  手動でGemini CLIを起動するには:"
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  # Managerを起動                                         │"
    echo "  │  tmux send-keys -t manager 'node /app/gemini-cli-src/bundle/gemini.js --model gemini-3-pro-preview --yolo' Enter │"
    echo "  │                                                          │"
    echo "  │  # Leader・Workerを一斉起動                              │"
    echo "  │  for i in {0..3}; do \\                                  │"
    echo "  │    tmux send-keys -t multiagent:0.\$i \\                 │"
    echo "  │      'node /app/gemini-cli-src/bundle/gemini.js --yolo' Enter       │"
    echo "  │  done                                                    │"
    echo "  └──────────────────────────────────────────────────────────┘"
    echo ""
fi



if [ "$SETUP_ONLY" = false ] && [ "$OPEN_TERMINAL" = false ]; then
    echo "  ════════════════════════════════════════════════════════════"
    echo "   システム起動完了！手動で各セッションにアタッチしてください。"
    echo "  ════════════════════════════════════════════════════════════"
    echo ""
    echo "  次のステップ:"
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  Managerセッションにアタッチ:                            │"
    echo "  │     tmux attach-session -t manager   (または: css)       │"
    echo "  │                                                          │"
    echo "  │  Leader・Workerセッションにアタッチ:                     │"
    echo "  │     tmux attach-session -t multiagent   (または: csm)    │"
    echo "  │                                                          │"
    echo "  │  ※ 各エージェントは指示書を読み込み済みです。            │"
    echo "  │    すぐに作業を開始できます。                            │"
    echo "  └──────────────────────────────────────────────────────────┘"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 8: Windows Terminal でタブを開く（-t オプション時のみ）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$OPEN_TERMINAL" = true ]; then
    log_info "📺 Windows Terminal でタブを展開中..."

    # Windows Terminal が利用可能か確認
    if command -v wt.exe &> /dev/null; then
        wt.exe -w 0 new-tab wsl.exe -e bash -c "tmux attach-session -t manager" \; new-tab wsl.exe -e bash -c "tmux attach-session -t multiagent"
        log_success "  └─ ターミナルタブ展開完了"
    else
        log_info "  └─ wt.exe が見つかりません。手動でアタッチしてください。"
    fi
    echo ""
fi
