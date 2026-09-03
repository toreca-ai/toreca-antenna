# トレカアンテナ 毎日自動投稿スクリプト
# Windowsタスクスケジューラから実行される想定。
# 前提: このスクリプトは toreca-antenna リポジトリのクローン直下に置くこと。
#       Claude Code (claude コマンド) がインストール済み・ `claude login` 済みであること。

$ErrorActionPreference = "Stop"
$RepoPath = $PSScriptRoot
Set-Location $RepoPath

New-Item -ItemType Directory -Force -Path "$RepoPath\logs" | Out-Null
$today = Get-Date -Format "yyyy-MM-dd"
$logFile = "$RepoPath\logs\daily-$today.json"

if (-not (git config user.email)) { git config user.email "toreca-antenna-bot@users.noreply.github.com" }
if (-not (git config user.name)) { git config user.name "toreca-antenna-bot" }

Write-Output "[$today] Pulling latest..."
git pull --ff-only

$prompt = @"
CONTENT_GUIDE.md の「毎日の自動生成タスクの手順」に厳密に従って、本日($today)分の記事を4本、生成してください。
1日4本では6テーマ全部に触れられません。直近7日間の data/posts.json のテーマ内訳を見て、本数が少ないテーマから4つ選んでください。同じ日に同じテーマを2本書かないこと。

書き始める前に data/vocab.md と data/insights.md を必ず読み、プレイヤーが実際に使う語彙と、いま議論されている論点を踏まえて書いてください。

タイトルの配分は CONTENT_GUIDE.md の「扱うタイトルの優先順位」に従ってください。主力はワンピースカード・デジモンカードゲーム・ドラゴンボール フュージョンワールド・ヴァイスシュヴァルツ・ヴァイスシュヴァルツロゼの5つです。
配分は1日4本のうち、主力5タイトルを明示した記事を2本以上、サブタイトルまたはタイトル横断・比較を1本、タイトル名を出さない一般論は1本以下にしてください。
1日では5タイトル全部に触れられないため週単位で回します。直近7日間に1本も出ていない主力タイトルがあれば、そのタイトルを最優先で選んでください。

本数を絞った分、1本あたりに時間をかけてください。調査を省略せず、必ず実施してください。
shinpan と souba のテーマでは、発売日・収録内容・効果テキストといった事実を公式の情報で確認してください。
guide と column のテーマでは、プレイヤーが書いた記事や投稿にあたって、使用感・評価の割れ方・言葉づかいを拾ってください。
調査で新しい用語や論点を得たら、data/vocab.md と data/insights.md の末尾に追記してください(既存の行は消さないこと)。

他サイトの文章や記事構成を真似しないでください。参照した個人の記事・投稿を名指しせず、意見は「使用者からは〜という声がある」のように一般化してください。
特定のショップ名・会社名・店舗URLは一切書かないでください。

data/posts.json を更新し、node tools/build-feed.js を実行して整合性チェックを通してから feed.xml と sitemap.xml を生成してください。
最後に、変更をコミットしてpushしてください(コミットメッセージ例: daily: automated post generation ($today))。
pushまで完了したら作業完了です。
"@

Write-Output "[$today] Running Claude Code..."
claude -p $prompt `
  --permission-mode acceptEdits `
  --allowedTools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch,Bash(git config *),Bash(git add *),Bash(git commit *),Bash(git push *),Bash(git pull *),Bash(git status *),Bash(git diff *),Bash(git log *),Bash(node *)" `
  --output-format json | Tee-Object -FilePath $logFile

Write-Output "[$today] Done. Log: $logFile"
