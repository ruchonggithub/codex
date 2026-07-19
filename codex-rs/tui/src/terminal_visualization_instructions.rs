use crate::legacy_core::config::Config;
use codex_features::Feature;

pub(crate) const TERMINAL_VISUALIZATION_INSTRUCTIONS: &str = "\
- 当前界面是终端。当格式规则要求使用可视化内容时，请在最终回答中使用紧凑的 ASCII 图、树、时间线或表格。
- 对精确映射或比较使用表格，不要把已知映射压缩成散文。
- 对层级或一对多关系使用树；对顺序、变化或按事件顺序在记录间传递的状态使用图或时间线。
- 可视化内容只能使用 ASCII 字符。";

pub(crate) fn with_terminal_visualization_instructions(
    config: &Config,
    control_instructions: Option<String>,
) -> Option<String> {
    if !config
        .features
        .enabled(Feature::TerminalVisualizationInstructions)
    {
        return control_instructions;
    }

    let existing_instructions =
        control_instructions.or_else(|| config.developer_instructions.clone());
    Some(match existing_instructions.as_deref() {
        Some(existing) if !existing.trim().is_empty() => {
            format!("{existing}\n\n{TERMINAL_VISUALIZATION_INSTRUCTIONS}")
        }
        _ => TERMINAL_VISUALIZATION_INSTRUCTIONS.to_string(),
    })
}
