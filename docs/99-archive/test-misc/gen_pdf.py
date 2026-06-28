#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AI 编程最佳实践指南 - PDF 生成脚本"""

from fpdf import FPDF

class PDF(FPDF):
    def __init__(self):
        super().__init__()
        # 加载中文字体
        self.add_font('SimHei', '', 'C:/Windows/Fonts/simhei.ttf', uni=True)
        self.add_font('SimHei', 'B', 'C:/Windows/Fonts/simhei.ttf', uni=True)
        self.add_font('SimHei', 'I', 'C:/Windows/Fonts/simhei.ttf', uni=True)

    def header(self):
        self.set_font('SimHei', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 5, 'AI 编程最佳实践指南 · 2026', 0, 1, 'R')
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font('SimHei', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f'第 {self.page_no()}/[nb] 页', 0, 0, 'C')

    def chapter_title(self, title):
        self.set_font('SimHei', 'B', 14)
        self.set_text_color(42, 65, 132)
        self.cell(0, 10, title, 0, 1, 'L')
        self.set_draw_color(49, 130, 206)
        self.set_line_width(0.5)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)

    def section_title(self, title):
        self.set_font('SimHei', 'B', 11)
        self.set_text_color(42, 65, 132)
        self.cell(0, 8, title, 0, 1, 'L')
        self.ln(2)

    def sub_section_title(self, title):
        self.set_font('SimHei', 'B', 10)
        self.set_text_color(66, 103, 178)
        self.cell(0, 7, title, 0, 1, 'L')
        self.ln(1)

    def body_text(self, text):
        self.set_font('SimHei', '', 10)
        self.set_text_color(50, 50, 50)
        self.multi_cell(0, 6, text)
        self.ln(2)

    def bullet_point(self, text, indent=15):
        self.set_font('SimHei', '', 10)
        self.set_text_color(50, 50, 50)
        self.set_x(indent)
        self.cell(5, 6, '•', 0, 0)
        self.multi_cell(0, 6, text)
        self.ln(1)

    def numbered_item(self, num, text, indent=15):
        self.set_font('SimHei', '', 10)
        self.set_text_color(50, 50, 50)
        self.set_x(indent)
        self.cell(8, 6, f'{num}.', 0, 0)
        self.multi_cell(0, 6, text)
        self.ln(1)

    def tip_box(self, text):
        self.set_fill_color(235, 248, 255)
        self.set_draw_color(49, 130, 206)
        self.set_line_width(0.3)
        x = self.get_x()
        y = self.get_y()
        self.set_font('SimHei', '', 10)
        self.set_text_color(42, 65, 132)
        self.multi_cell(0, 6, text, 0, 'L')
        h = self.get_y() - y
        self.rect(x, y, 190, h, 'DF')
        self.ln(4)

    def warning_box(self, text):
        self.set_fill_color(255, 251, 235)
        self.set_draw_color(214, 158, 46)
        self.set_line_width(0.3)
        x = self.get_x()
        y = self.get_y()
        self.set_font('SimHei', '', 10)
        self.set_text_color(100, 80, 40)
        self.multi_cell(0, 6, text, 0, 'L')
        h = self.get_y() - y
        self.rect(x, y, 190, h, 'DF')
        self.ln(4)

    def danger_box(self, text):
        self.set_fill_color(255, 245, 245)
        self.set_draw_color(229, 62, 62)
        self.set_line_width(0.3)
        x = self.get_x()
        y = self.get_y()
        self.set_font('SimHei', '', 10)
        self.set_text_color(160, 40, 40)
        self.multi_cell(0, 6, text, 0, 'L')
        h = self.get_y() - y
        self.rect(x, y, 190, h, 'DF')
        self.ln(4)

    def success_box(self, text):
        self.set_fill_color(240, 255, 244)
        self.set_draw_color(56, 161, 105)
        self.set_line_width(0.3)
        x = self.get_x()
        y = self.get_y()
        self.set_font('SimHei', '', 10)
        self.set_text_color(40, 100, 60)
        self.multi_cell(0, 6, text, 0, 'L')
        h = self.get_y() - y
        self.rect(x, y, 190, h, 'DF')
        self.ln(4)

    def code_block(self, text):
        self.set_font('SimHei', '', 8)
        self.set_text_color(220, 220, 220)
        self.set_fill_color(30, 41, 59)
        lines = text.strip().split('\n')
        h = len(lines) * 4.5 + 6
        x = self.get_x()
        y = self.get_y()
        self.rect(x, y, 190, h, 'DF')
        self.set_xy(x + 3, y + 3)
        for line in lines:
            self.cell(184, 4.5, line, 0, 1)
        self.set_xy(x, y + h + 3)

    def table_header(self, headers):
        self.set_font('SimHei', 'B', 9)
        self.set_fill_color(49, 130, 206)
        self.set_text_color(255, 255, 255)
        col_widths = [40, 40, 40, 40, 40, 30]
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 7, h, 1, 0, 'C', True)
        self.ln()
        self.set_draw_color(200, 200, 200)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(1)

    def table_row(self, data, fill=False):
        self.set_font('SimHei', '', 8)
        self.set_text_color(50, 50, 50)
        col_widths = [40, 40, 40, 40, 40, 30]
        if fill:
            self.set_fill_color(245, 247, 250)
        for i, d in enumerate(data):
            self.cell(col_widths[i], 6, str(d), 1, 0, 'L', fill)
        self.ln()

pdf = PDF()
pdf.alias_nb_pages()
pdf.set_auto_page_break(auto=True, margin=20)

# 封面页
pdf.add_page()
pdf.ln(60)
pdf.set_font('SimHei', 'B', 28)
pdf.set_text_color(26, 54, 93)
pdf.cell(0, 15, 'AI 编程最佳实践指南', 0, 1, 'C')
pdf.ln(10)
pdf.set_font('SimHei', '', 14)
pdf.set_text_color(113, 128, 150)
pdf.cell(0, 10, '从入门到精通 · 2026 年最新版', 0, 1, 'C')
pdf.ln(30)
pdf.set_font('SimHei', '', 10)
pdf.set_text_color(160, 174, 192)
pdf.cell(0, 6, '编写日期：2026 年 6 月', 0, 1, 'C')
pdf.cell(0, 6, '适用工具：Cursor · Trae · Windsurf · Copilot · Claude Code', 0, 1, 'C')
pdf.cell(0, 6, '技术栈：不限（通用方法论）', 0, 1, 'C')

# 目录
pdf.add_page()
pdf.set_font('SimHei', 'B', 16)
pdf.set_text_color(26, 54, 93)
pdf.cell(0, 12, '📑 目录', 0, 1, 'L')
pdf.ln(8)

toc = [
    '一、AI 编程思维重塑',
    '二、提示词工程核心技巧',
    '三、开发环境配置最佳实践',
    '四、项目级 AI 协作工作流',
    '五、代码质量与安全',
    '六、常见陷阱与避坑指南',
    '七、进阶：Agent 与 MCP',
    '八、工具选型与对比',
    '九、AI 编程 Checklist'
]

for i, item in enumerate(toc, 1):
    pdf.set_font('SimHei', '', 11)
    pdf.set_text_color(45, 45, 45)
    pdf.cell(0, 8, f'{item}', 0, 1, 'L')

# 第一章：思维重塑
pdf.add_page()
pdf.chapter_title('一、AI 编程思维重塑')

pdf.section_title('1.1 核心认知转变')
pdf.table_header(['传统编程', 'AI 辅助编程'])
pdf.table_row(['我是程序员，AI 是工具', '我是架构师，AI 是高级初级工程师'], True)
pdf.table_row(['一行一行写代码', '设计需求→AI 生成→我审查→迭代优化'])
pdf.table_row(['遇到问题查 Stack Overflow', '直接把代码丢给 AI，让它分析'], True)
pdf.table_row(['自己测试', '让 AI 写测试用例，我来验证'])
pdf.table_row(['一个人搞定一切', '多人分工：架构师 + 代码审查员 + 测试员'])
pdf.ln(4)

pdf.warning_box('⚠️ 最重要的心态转变：\n"AI 帮我节省了 80% 的时间，剩下的 20% 我来打磨。"\n不要指望 AI 一次出完美代码——迭代才是核心能力。')

pdf.section_title('1.2 正确的角色定位')
pdf.body_text('在 AI 辅助编程中，你需要扮演三个角色：')
pdf.numbered_item(1, '产品经理（PM）——明确需求、定义边界、验收交付物')
pdf.numbered_item(2, '架构师（Architect）——设计技术选型、模块划分、数据流向')
pdf.numbered_item(3, '代码审查员（Reviewer）——逐行检查 AI 生成的代码，确保正确性和安全性')
pdf.ln(2)
pdf.body_text('AI 是你的高级工程师，它干活，你把关。这个分工不能反。')

# 第二章：提示词工程
pdf.add_page()
pdf.chapter_title('二、提示词工程核心技巧')

pdf.section_title('2.1 万能提示词模板')
pdf.code_block('[角色]\n你是一位资深 {语言} 开发工程师，精通 {框架/库}。\n\n[背景]\n我正在开发一个 {项目描述}，使用 {技术栈}。\n\n[需求]\n请实现 {具体功能}，要求：\n1. {验收标准1}\n2. {验收标准2}\n3. {验收标准3}\n\n[约束]\n- 不要使用 {不想要的内容}\n- 必须遵循 {项目规范}\n- 代码需要包含 {注释/类型/文档}\n\n[示例]\n参考以下代码风格：\n{粘贴示例代码}\n\n[输出]\n请输出完整代码，并在代码后附上：\n1. 使用说明\n2. 已知限制')

pdf.section_title('2.2 六大核心技巧')
pdf.table_header(['技巧', '说明', '示例'])
pdf.table_row(['指定角色', '给 AI 一个专业身份', '"你是一位安全专家..."'], True)
pdf.table_row(['提供上下文', '给足够的项目背景', '"这是一个 Flutter 项目，使用 Riverpod..."'])
pdf.table_row(['分步思考', '要求 AI 一步步分析', '"先分析需求，再设计架构，最后写代码"'], True)
pdf.table_row(['给出示例', '用示例代码定义期望', '"参考以下代码风格：..."'])
pdf.table_row(['明确约束', '告诉 AI 不要做什么', '"不要使用任何 any 类型"'], True)
pdf.table_row(['要求输出格式', '规定输出结构', '"输出完整代码 + 使用说明 + 已知限制"'])
pdf.ln(4)

pdf.section_title('2.3 错误 vs 正确提示词')
pdf.danger_box('❌ 错误示例："帮我写一个登录功能"')
pdf.success_box('✅ 正确示例："我需要一个 Flutter 项目的用户登录功能，使用 Firebase Auth。\n要求：\n1. 支持邮箱 + 密码登录\n2. 有加载状态和错误提示\n3. 使用 Riverpod 做状态管理\n4. 输入框有基本验证\n5. 参考现有项目的代码风格（已附示例）\n请先列出实现步骤，确认后再输出代码。"')

pdf.section_title('2.4 复杂任务拆解技巧')
pdf.body_text('遇到复杂功能时，不要一次丢一个大需求，拆成多个小步骤：')
pdf.code_block('第一步：生成数据模型（User, Order, Item）\n第二步：生成 API 接口层\n第三步：生成 UI 组件\n第四步：集成测试')
pdf.body_text('每步确认后再进入下一步。这样 AI 的输出质量更高，你也更容易审查。')

# 第三章：开发环境配置
pdf.add_page()
pdf.chapter_title('三、开发环境配置最佳实践')

pdf.section_title('3.1 项目级配置（Rules）')
pdf.body_text('在根目录创建 .cursorrules 或 .cursor/rules.md，定义项目规范：')
pdf.code_block('# 项目规范\n- 语言：Dart 3.5+\n- 框架：Flutter 3.24\n- 状态管理：Riverpod\n- 路由：go_router\n- 命名：文件使用 snake_case，类使用 PascalCase\n- 错误：统一使用 Result 模式，返回 {success, data, error}\n- 禁止：使用 any 类型、魔法字符串、硬编码 URL\n- 必须：每个函数有 doc comment、每个 widget 有注释说明用途')
pdf.body_text('这样每次对话时，AI 自动遵守项目规范，不需要重复说明。')

pdf.section_title('3.2 AI 模型配置策略')
pdf.body_text('根据任务类型切换不同的 AI 模型：')
pdf.table_header(['任务类型', '推荐模型', '原因'])
pdf.table_row(['日常代码补全', '轻量模型 / Tab 自动补全', '速度快，成本低'], True)
pdf.table_row(['复杂架构设计', '最强模型（Claude/GPT-4o）', '需要深度推理'])
pdf.table_row(['代码审查', '推理能力强的模型', '需要发现隐藏问题'], True)
pdf.table_row(['调试错误', '带代码分析能力的模型', '需要理解错误上下文'])
pdf.table_row(['文档生成', '文本生成能力强的模型', '需要清晰表达'])
pdf.ln(4)
pdf.tip_box('💡 省钱技巧：日常用本地模型（免费），重要任务切云端最强模型。混合使用，效果和成本兼顾。')

pdf.section_title('3.3 Git 集成最佳实践')
pdf.code_block('# 每次 AI 生成代码后，养成习惯：\n1. 先审查代码（逐行看）\n2. 本地运行测试\n3. git add + commit 后再进入下一步\n4. commit message 注明 AI 参与了哪些修改')

# 第四章：项目级协作工作流
pdf.add_page()
pdf.chapter_title('四、项目级 AI 协作工作流')

pdf.section_title('4.1 从需求到上线的完整流程')
pdf.tip_box('📋 标准流程：\n需求分析 → 架构设计 → 代码生成 → 审查 → 测试 → 迭代 → 上线')

pdf.sub_section_title('阶段 1：需求分析')
pdf.code_block('提示词：\n"我需要一个{项目描述}，目标用户是{用户群体}，\n核心功能是{功能1、2、3}。请帮我：\n1. 列出用户故事（User Stories）\n2. 列出非功能需求（性能、安全等）\n3. 列出 MVP 范围（最小可发布版本）\n4. 列出后续迭代方向"')

pdf.sub_section_title('阶段 2：架构设计')
pdf.code_block('提示词：\n"基于以下需求：{粘贴需求分析}，请帮我设计：\n1. 技术选型及理由\n2. 模块划分（包含依赖关系图）\n3. 数据模型设计\n4. API 接口设计\n5. 目录结构\n请先给出方案，我确认后再细化。"')

pdf.sub_section_title('阶段 3：代码生成（按模块逐个来）')
pdf.code_block('提示词：\n"请先实现数据模型层。\n技术栈：{列出}\n参考项目现有代码风格：{粘贴示例}\n输出：完整代码 + 说明"')

pdf.sub_section_title('阶段 4：审查与测试')
pdf.code_block('提示词：\n"请作为代码审查员，审查以下代码：\n1. 是否存在安全风险？\n2. 是否有性能问题？\n3. 是否符合项目规范？\n4. 是否有更好的写法？\n5. 请生成对应的单元测试"')

pdf.section_title('4.2 多 Agent 协作模式')
pdf.body_text('对于大型项目，可以同时启动多个 AI 对话，分工协作：')
pdf.table_header(['角色', '负责内容', '对话方式'])
pdf.table_row(['架构 Agent', '整体设计、技术方案', '一次对话定方案'], True)
pdf.table_row(['前端 Agent', 'UI 组件、状态管理', '按组件逐个生成'])
pdf.table_row(['后端 Agent', 'API、数据库、业务逻辑', '按接口逐个生成'], True)
pdf.table_row(['测试 Agent', '单元测试、集成测试', '拿到代码后自动测试'])
pdf.ln(4)
pdf.success_box('💡 实际场景：你在一个对话里让 AI 设计架构，在另一个对话里让同一个 AI 生成 UI 代码，在第三个对话里让它审查后端代码。三个对话独立运行，互不干扰。')

# 第五章：代码质量与安全
pdf.add_page()
pdf.chapter_title('五、代码质量与安全')

pdf.section_title('5.1 AI 生成代码的六大必查项')
pdf.table_header(['#', '检查项', '说明', '严重程度'])
pdf.table_row(['1', 'API 密钥泄露', '硬编码的密钥、Token 必须抽离到环境变量', '🔴 高'], True)
pdf.table_row(['2', 'SQL 注入', '拼接 SQL 字符串而非使用参数化查询', '🔴 高'])
pdf.table_row(['3', 'XSS 漏洞', '直接渲染用户输入未转义', '🔴 高'], True)
pdf.table_row(['4', '异常处理缺失', 'try-catch 不完整，静默吞掉异常', '🟡 中'])
pdf.table_row(['5', '类型安全问题', '使用 any、dynamic 导致运行时崩溃', '🟡 中'], True)
pdf.table_row(['6', '性能隐患', 'N+1 查询、未缓存的重复计算', '🟢 低'])
pdf.ln(4)

pdf.section_title('5.2 安全最佳实践')
pdf.danger_box('🚫 绝对不要做：\n- 把 AI 生成代码中的 API 密钥直接提交到 Git\n- 把生产环境数据库密码告诉 AI\n- 让 AI 访问你的真实用户数据')

pdf.success_box('✅ 应该这样做：\n- 使用测试数据（伪造数据）让 AI 生成代码\n- 密钥全部走环境变量 / 密钥管理服务\n- 用 .env.example 文件展示密钥格式，不填真实值')

pdf.section_title('5.3 让 AI 做代码审查')
pdf.code_block('"请审查以下代码，重点关注：\n1. 安全风险（注入、XSS、CSRF 等）\n2. 边界条件处理（空值、越界、超时）\n3. 性能问题（循环内查询、不必要的计算）\n4. 代码风格一致性\n5. 是否有更优实现方案\n请逐条列出问题和建议。"')

# 第六章：常见陷阱
pdf.add_page()
pdf.chapter_title('六、常见陷阱与避坑指南')

pdf.section_title('6.1 新手最常犯的 8 个错误')
pdf.table_header(['错误', '后果', '正确做法'])
pdf.table_row(['一次给太多需求', 'AI 输出混乱，部分功能被忽略', '拆成小步骤，逐个完成'], True)
pdf.table_row(['不审查直接运行', 'Bug 多，调试成本高', '逐行审查 + 单元测试'])
pdf.table_row(['不更新上下文', 'AI 用旧代码生成新代码', '每次对话都告知当前项目状态'], True)
pdf.table_row(['过度依赖一个工具', '工具限制 = 你的上限', '多工具交叉验证'])
pdf.table_row(['不写测试', '改了一处，坏了三处', 'AI 写测试，你验证测试'], True)
pdf.table_row(['不学基础', '无法审查 AI 代码', '基础能力是审查能力的底气'])
pdf.table_row(['复制粘贴不读', '引入无用代码、安全风险', '每行代码都要理解'], True)
pdf.table_row(['不保留版本', '改乱了无法回退', '频繁 commit，善用 Git'])
pdf.ln(4)

pdf.section_title('6.2 "AI 幻觉" 应对策略')
pdf.body_text('AI 有时会"一本正经地胡说八道"——引用不存在的 API、编造不存在的库。')
pdf.code_block('应对方法：\n1. 对 AI 输出的 API/库/版本做验证（查官方文档）\n2. 让 AI 给出代码后，用 `dart pub deps` / `npm list` 验证\n3. 如果编译报错，把错误信息丢给 AI 让它修复\n4. 重要功能先用最小 demo 验证思路，再集成')

pdf.warning_box('⚠️ 记住：AI 说"这个 API 存在于 Flutter 3.24"——你去 dart.dev 查一下再相信。')

# 第七章：进阶
pdf.add_page()
pdf.chapter_title('七、进阶：Agent 与 MCP')

pdf.section_title('7.1 MCP（模型上下文协议）')
pdf.body_text('MCP 让 AI 能访问外部工具和数据源。相当于给 AI 装上"手和脚"：')
pdf.table_header(['能力', '说明', '示例 MCP'])
pdf.table_row(['文件系统', '读写项目文件', 'filesystem MCP'], True)
pdf.table_row(['数据库', '查询/操作数据库', 'postgres MCP'])
pdf.table_row(['终端', '执行命令行命令', 'shell MCP'], True)
pdf.table_row(['网络', '调用 API / 爬取数据', 'web-fetch MCP'])
pdf.table_row(['代码分析', '静态分析 / 重构', 'eslint MCP'])
pdf.ln(4)

pdf.section_title('7.2 Skills（技能定义）')
pdf.body_text('Skills 是用 Markdown 文件定义的"专家模式"：')
pdf.code_block('# skills/database/SKILL.md\n# 数据库专家\n当你处理数据库相关问题时，遵循以下规范：\n1. 使用参数化查询防止 SQL 注入\n2. 每个查询必须有超时限制（30s）\n3. 数据库迁移使用 migration 文件管理\n4. 索引设计原则：...\n5. 连接池大小 = CPU 核心数 × 2')
pdf.body_text('配置后，当你讨论数据库问题时，AI 会自动应用这些规则。')

pdf.section_title('7.3 Hooks（自动化钩子）')
pdf.body_text('让 AI 在特定操作时自动执行任务：')
pdf.code_block('{\n  "onSave": [\n    "npx prettier --write {file}",\n    "npx eslint --fix {file}"\n  ],\n  "beforeCommit": [\n    "npm test",\n    "git diff --stat"\n  ]\n}')

# 第八章：工具选型
pdf.add_page()
pdf.chapter_title('八、工具选型与对比')

pdf.section_title('8.1 2026 主流 AI 编程工具对比')
pdf.table_header(['工具', '类型', '价格', '优势', '劣势', '适合谁'])
pdf.table_row(['Cursor', 'IDE（VS Code fork）', '$0~$60/月', '模型灵活、Composer 多文件编辑、MCP 支持', '高级功能需付费', '全栈开发者'], True)
pdf.table_row(['Trae', 'IDE（VS Code fork）', '免费', '中文最佳、免费、Builder 模式一键生成', '生态较新', '中文开发者、初学者'])
pdf.table_row(['Windsurf', 'IDE（VS Code fork）', '$0~$20/月', 'Flow 模式流程引导、补全速度快', '团队版调整中', '前端、全栈开发'], True)
pdf.table_row(['Copilot', 'IDE 插件', '$10/月', '生态最广、IDE 兼容性好', '独立能力弱，依赖宿主 IDE', '已有 IDE 的用户'])
pdf.table_row(['Claude Code', 'CLI Agent', '按量计费', '推理最强、代码质量最高', '命令行操作，学习曲线', '后端、架构师'], True)
pdf.table_row(['OpenClaw', 'AI Agent 平台', '免费/开源', '本地部署、支持自定义模型、MCP + Skills', '文档和社区较新', '注重隐私、想自定义'])
pdf.ln(4)

pdf.section_title('8.2 针对 Flutter/Android 开发的推荐组合')
pdf.success_box('🏆 最佳实践组合：\n\n方案 A（推荐）：Cursor（写代码）+ 本地模型（省钱）+ Android Studio（编译调试）\n方案 B（免费）：Trae 基础版 + 本地模型\n方案 C（最强）：Claude Code（架构）+ Cursor（日常）+ Android Studio')

# 第九章：Checklist
pdf.add_page()
pdf.chapter_title('九、AI 编程 Checklist')
pdf.body_text('每次使用 AI 辅助编程时，按这个清单逐项检查：')

pdf.sub_section_title('写提示词之前')
pdf.numbered_item(1, '我是否已经理解了需求的完整范围？')
pdf.numbered_item(2, '我是否准备好了上下文（技术栈、代码示例、项目规范）？')
pdf.numbered_item(3, '这个需求是否可以拆成更小的步骤？')

pdf.ln(3)
pdf.sub_section_title('收到 AI 输出后')
pdf.numbered_item(4, '我逐行审查了代码吗？')
pdf.numbered_item(5, 'API 调用是否正确？版本是否匹配？')
pdf.numbered_item(6, '有没有安全漏洞（密钥泄露、注入）？')
pdf.numbered_item(7, '有没有多余的、不需要的代码？')
pdf.numbered_item(8, '错误处理是否完整？')
pdf.numbered_item(9, '代码风格是否符合项目规范？')

pdf.ln(3)
pdf.sub_section_title('运行和测试后')
pdf.numbered_item(10, '本地编译/运行成功了吗？')
pdf.numbered_item(11, '单元测试通过了吗？')
pdf.numbered_item(12, 'Edge case（边界条件）测试了吗？')
pdf.numbered_item(13, 'git commit 了吗？')
pdf.numbered_item(14, '更新了项目文档吗？')

pdf.ln(10)
pdf.tip_box('📌 最后的话\n\nAI 编程工具再强大，也改变不了一个事实：好软件需要时间打磨。\n\nAI 帮你省掉了从 0 到 1 的枯燥工作，但 1 到 100 的优化、打磨、测试，\n依然需要你亲自动手。\n\n把 AI 当助手，不是替代品。慢慢来，享受过程。')

pdf.ln(10)
pdf.set_font('SimHei', 'I', 9)
pdf.set_text_color(160, 174, 192)
pdf.cell(0, 6, '— 本指南由 AI 辅助生成，人类审查 —', 0, 1, 'C')
pdf.cell(0, 6, '2026 年 6 月', 0, 1, 'C')

# 输出
output_path = 'C:/Users/jiaqi/.openclaw/workspace/projects/ai-travel-ledger/AI编程最佳实践指南.pdf'
pdf.output(output_path)
print(f'PDF 生成成功！\n路径：{output_path}')
