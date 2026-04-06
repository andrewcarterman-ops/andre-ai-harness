import streamlit as st
import subprocess
import os
import json
from pathlib import Path

# Configuration
SKILLS_DIR = Path.home() / ".openclaw" / "workspace" / "skills"
MISSION_CONTROL_DIR = SKILLS_DIR / "mission-control"


def generate_chat_response(prompt):
    """Generate a response based on user input"""
    prompt_lower = prompt.lower()
    
    # Tool creation
    if any(word in prompt_lower for word in ["create", "new tool", "build", "make"]):
        return "I can help you create a tool! Go to the '➕ Create Tool' tab and choose a template. What kind of tool do you want to build?"
    
    # Templates
    if any(word in prompt_lower for word in ["template", "templates", "types"]):
        return "We have 6 templates:\n\n- 🔗 **API Connector** - Connect to external APIs\n- 📁 **File Processor** - Work with files\n- 🔄 **Data Transformer** - Convert data formats\n- ⚙️ **Automation** - Automate tasks\n- 🔌 **Integration** - Connect services\n- 🎨 **Custom** - Build anything\n\nCheck '📚 Templates' for more details!"
    
    # List tools
    if any(word in prompt_lower for word in ["my tools", "list tools", "show tools"]):
        tools = [d.name for d in SKILLS_DIR.iterdir() if d.is_dir() and d.name != "mission-control"]
        if tools:
            return f"Your tools:\n\n" + "\n".join(f"- {t}" for t in tools)
        else:
            return "You don't have any tools yet. Go to '➕ Create Tool' to build your first one!"
    
    # Help
    if any(word in prompt_lower for word in ["help", "how to", "?"]):
        return "Here's what you can do in Mission Control:\n\n- **🏠 Dashboard** - Overview and quick start\n- **💬 Chat** - Talk to me (you're here!)\n- **➕ Create Tool** - Build new tools\n- **📦 My Tools** - Manage existing tools\n- **📚 Templates** - Browse templates\n- **⚙️ Settings** - Configuration\n\nWhat would you like to do?"
    
    # Greeting
    if any(word in prompt_lower for word in ["hello", "hi", "hey"]):
        return "Hey there! 👋 I'm Andrew, your AI assistant. Ready to build some tools?"
    
    # Default response
    return f"I'm listening! You said: '{prompt}'\n\nI'm still learning to communicate through this interface. For now, I can help you:\n\n- Create tools\n- Show templates\n- List your tools\n- Answer questions about Mission Control\n\nWhat would you like to do?"

# Page config
st.set_page_config(
    page_title="Mission Control",
    page_icon="🚀",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        font-weight: bold;
        background: linear-gradient(90deg, #ff6b6b, #4ecdc4);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }
    .card {
        background: #f8f9fa;
        border-radius: 10px;
        padding: 20px;
        margin: 10px 0;
        border-left: 4px solid #4ecdc4;
    }
    .tool-card {
        background: white;
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 15px;
        margin: 10px 0;
        transition: all 0.3s;
    }
    .tool-card:hover {
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        transform: translateY(-2px);
    }
    .stButton>button {
        background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
        border-radius: 25px;
        padding: 10px 24px;
        font-weight: bold;
    }
    .stButton>button:hover {
        background: linear-gradient(90deg, #764ba2 0%, #667eea 100%);
    }
</style>
""", unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.markdown("## 🚀 Mission Control")
    st.markdown("---")
    
    page = st.radio(
        "Navigation",
        ["🏠 Dashboard", "💬 Chat", "➕ Create Tool", "📦 My Tools", "📚 Templates", "⚙️ Settings"]
    )
    
    st.markdown("---")
    st.markdown("### Quick Actions")
    
    if st.button("🔄 Refresh"):
        st.rerun()
    
    st.markdown("---")
    st.markdown("Made with ❤️ by Andrew")

# Dashboard Page
if "🏠 Dashboard" in page:
    st.markdown('<p class="main-header">🚀 Mission Control</p>', unsafe_allow_html=True)
    st.markdown("### Your personal tool factory")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.markdown("""
        <div class="card">
            <h3>📊 Stats</h3>
            <p>Tools created: <strong>{}</strong></p>
            <p>Active tools: <strong>{}</strong></p>
        </div>
        """.format(
            len([d for d in SKILLS_DIR.iterdir() if d.is_dir()]),
            len([d for d in SKILLS_DIR.iterdir() if d.is_dir()])
        ), unsafe_allow_html=True)
    
    with col2:
        st.markdown("""
        <div class="card">
            <h3>⚡ Quick Start</h3>
            <p>Create your first tool in seconds!</p>
            <p>Choose from 6 templates</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col3:
        st.markdown("""
        <div class="card">
            <h3>🔧 Available</h3>
            <p>API Connectors</p>
            <p>File Processors</p>
            <p>Automation Tools</p>
        </div>
        """, unsafe_allow_html=True)
    
    st.markdown("---")
    st.markdown("### 🎯 What would you like to build?")
    
    cols = st.columns(3)
    templates = [
        ("🔗 API Connector", "Connect to external APIs", "api-connector"),
        ("📁 File Processor", "Process files and documents", "file-processor"),
        ("🔄 Data Transformer", "Transform data formats", "data-transformer"),
        ("⚙️ Automation", "Automate repetitive tasks", "automation"),
        ("🔌 Integration", "Integrate with services", "integration"),
        ("🎨 Custom", "Build something unique", "custom"),
    ]
    
    for i, (name, desc, template_type) in enumerate(templates):
        with cols[i % 3]:
            st.markdown(f"""
            <div class="tool-card">
                <h4>{name}</h4>
                <p>{desc}</p>
            </div>
            """, unsafe_allow_html=True)
            if st.button(f"Create {name.split()[0]}", key=f"dash_{template_type}"):
                st.session_state['create_template'] = template_type
                st.rerun()

# Chat Page
elif "💬 Chat" in page:
    st.markdown('<p class="main-header">💬 Chat with Andrew</p>', unsafe_allow_html=True)
    st.markdown("### Your AI assistant inside Mission Control")
    
    # Initialize chat history
    if "messages" not in st.session_state:
        st.session_state.messages = [
            {"role": "assistant", "content": "Hey! I'm Andrew, your AI assistant. I'm running inside Mission Control now! How can I help you today? 🚀"}
        ]
    
    # Display chat messages
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])
    
    # Chat input
    if prompt := st.chat_input("What would you like to know?"):
        # Add user message to chat history
        st.session_state.messages.append({"role": "user", "content": prompt})
        
        # Display user message
        with st.chat_message("user"):
            st.markdown(prompt)
        
        # Generate response based on context
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                # Simple response logic for now
                response = generate_chat_response(prompt)
                st.markdown(response)
        
        # Add assistant response to chat history
        st.session_state.messages.append({"role": "assistant", "content": response})
    
    # Chat controls
    st.markdown("---")
    col1, col2, col3 = st.columns(3)
    
    with col1:
        if st.button("🗑️ Clear Chat"):
            st.session_state.messages = [
                {"role": "assistant", "content": "Chat cleared! How can I help you? 🚀"}
            ]
            st.rerun()
    
    with col2:
        if st.button("💾 Save Chat"):
            chat_file = SKILLS_DIR / "mission-control" / "chat_history.json"
            with open(chat_file, "w", encoding="utf-8") as f:
                json.dump(st.session_state.messages, f, indent=2, ensure_ascii=False)
            st.success(f"Chat saved to {chat_file}")
    
    with col3:
        if st.button("📂 Open Chat Folder"):
            os.startfile(str(SKILLS_DIR / "mission-control"))
    
    # Quick actions
    st.markdown("---")
    st.markdown("### ⚡ Quick Actions")
    
    quick_cols = st.columns(4)
    
    with quick_cols[0]:
        if st.button("🛠️ Create a Tool"):
            st.session_state.messages.append({
                "role": "user", 
                "content": "I want to create a new tool. What templates are available?"
            })
            st.session_state.messages.append({
                "role": "assistant",
                "content": "Great! I can help you create a tool. Go to the '➕ Create Tool' tab or tell me what kind of tool you need:\n\n- 🔗 API Connector\n- 📁 File Processor\n- 🔄 Data Transformer\n- ⚙️ Automation\n- 🔌 Integration\n- 🎨 Custom"
            })
            st.rerun()
    
    with quick_cols[1]:
        if st.button("📚 Show Templates"):
            st.session_state.messages.append({
                "role": "user",
                "content": "Show me the available templates"
            })
            st.session_state.messages.append({
                "role": "assistant",
                "content": "We have 6 templates:\n\n1. **API Connector** - For connecting to external APIs\n2. **File Processor** - For processing files and documents\n3. **Data Transformer** - For converting data formats\n4. **Automation** - For automating tasks\n5. **Integration** - For integrating services\n6. **Custom** - Start from scratch\n\nGo to '📚 Templates' to see details!"
            })
            st.rerun()
    
    with quick_cols[2]:
        if st.button("🔧 My Tools"):
            tool_count = len([d for d in SKILLS_DIR.iterdir() if d.is_dir() and d.name != "mission-control"])
            st.session_state.messages.append({
                "role": "user",
                "content": "Show me my tools"
            })
            st.session_state.messages.append({
                "role": "assistant",
                "content": f"You have {tool_count} tool(s). Go to '📦 My Tools' to see them all!"
            })
            st.rerun()
    
    with quick_cols[3]:
        if st.button("❓ Help"):
            st.session_state.messages.append({
                "role": "user",
                "content": "I need help"
            })
            st.session_state.messages.append({
                "role": "assistant",
                "content": "I'm here to help! You can:\n\n- Create new tools with templates\n- Manage existing tools\n- Get information about Mission Control\n- Ask me anything about building tools\n\nWhat would you like to do?"
            })
            st.rerun()

# Create Tool Page
elif "➕ Create Tool" in page:
    st.markdown('<p class="main-header">➕ Create New Tool</p>', unsafe_allow_html=True)
    
    with st.form("create_tool_form"):
        st.markdown("### Tool Information")
        
        tool_name = st.text_input(
            "Tool Name",
            placeholder="my-awesome-tool",
            help="Use lowercase letters, numbers, and hyphens only"
        )
        
        tool_type = st.selectbox(
            "Template Type",
            [
                ("api-connector", "🔗 API Connector - Connect to external APIs"),
                ("file-processor", "📁 File Processor - Process files and documents"),
                ("data-transformer", "🔄 Data Transformer - Transform data formats"),
                ("automation", "⚙️ Automation - Automate repetitive tasks"),
                ("integration", "🔌 Integration - Integrate with services"),
                ("custom", "🎨 Custom - Build something unique"),
            ],
            format_func=lambda x: x[1],
            index=0 if 'create_template' not in st.session_state else 
                  [t[0] for t in [("api-connector", ""), ("file-processor", ""), ("data-transformer", ""), 
                                  ("automation", ""), ("integration", ""), ("custom", "")]].index(st.session_state.get('create_template', 'api-connector'))
        )
        
        tool_description = st.text_area(
            "Description (optional)",
            placeholder="What does this tool do?",
            help="This helps the AI understand when to use your tool"
        )
        
        st.markdown("---")
        
        submitted = st.form_submit_button("🚀 Create Tool", use_container_width=True)
        
        if submitted:
            if not tool_name:
                st.error("❌ Please enter a tool name!")
            elif not tool_name.replace("-", "").replace("_", "").isalnum():
                st.error("❌ Tool name must contain only letters, numbers, and hyphens!")
            else:
                with st.spinner("Creating your tool..."):
                    try:
                        # Run the mission_control.py script
                        script_path = MISSION_CONTROL_DIR / "scripts" / "mission_control.py"
                        result = subprocess.run(
                            [
                                "python", str(script_path),
                                "create", tool_name,
                                "--type", tool_type[0],
                                "--path", str(SKILLS_DIR)
                            ],
                            capture_output=True,
                            text=True
                        )
                        
                        if result.returncode == 0:
                            st.success(f"✅ Tool '{tool_name}' created successfully!")
                            st.code(result.stdout)
                            
                            # Show next steps
                            st.markdown("### 📋 Next Steps")
                            st.markdown(f"""
                            Your tool is at: `{SKILLS_DIR / tool_name}`
                            
                            1. **Edit SKILL.md** - Add your description and usage
                            2. **Implement scripts** - Write your logic in `scripts/`
                            3. **Test it** - Run the scripts
                            4. **Use it** - Ask me to use your tool!
                            """)
                        else:
                            st.error(f"❌ Error: {result.stderr}")
                    except Exception as e:
                        st.error(f"❌ Error: {str(e)}")

# My Tools Page
elif "📦 My Tools" in page:
    st.markdown('<p class="main-header">📦 My Tools</p>', unsafe_allow_html=True)
    
    if SKILLS_DIR.exists():
        tools = [d for d in SKILLS_DIR.iterdir() if d.is_dir() and d.name != "mission-control"]
        
        if not tools:
            st.info("🤔 No tools yet! Go to 'Create Tool' to build your first one.")
        else:
            st.markdown(f"You have **{len(tools)}** tool(s)")
            
            for tool in sorted(tools):
                skill_md = tool / "SKILL.md"
                description = "No description available"
                
                if skill_md.exists():
                    content = skill_md.read_text(encoding="utf-8")
                    # Extract description from frontmatter
                    if "description:" in content:
                        for line in content.split("\n"):
                            if line.strip().startswith("description:"):
                                description = line.split(":", 1)[1].strip()
                                break
                
                with st.expander(f"🔧 {tool.name}"):
                    col1, col2 = st.columns([3, 1])
                    
                    with col1:
                        st.markdown(f"**Description:** {description}")
                        st.markdown(f"**Location:** `{tool}`")
                        
                        # Show scripts
                        scripts_dir = tool / "scripts"
                        if scripts_dir.exists():
                            scripts = list(scripts_dir.glob("*.py"))
                            if scripts:
                                st.markdown("**Scripts:**")
                                for script in scripts:
                                    st.markdown(f"- `{script.name}`")
                    
                    with col2:
                        if st.button("📂 Open Folder", key=f"open_{tool.name}"):
                            os.startfile(str(tool))
                        
                        if st.button("📝 Edit SKILL.md", key=f"edit_{tool.name}"):
                            os.startfile(str(skill_md))
                        
                        if st.button("🗑️ Delete", key=f"del_{tool.name}"):
                            st.warning("Delete functionality coming soon!")
    else:
        st.error(f"❌ Skills directory not found: {SKILLS_DIR}")

# Templates Page
elif "📚 Templates" in page:
    st.markdown('<p class="main-header">📚 Templates</p>', unsafe_allow_html=True)
    
    templates = {
        "api-connector": {
            "icon": "🔗",
            "name": "API Connector",
            "description": "Connect to external APIs with authentication, rate limiting, and error handling.",
            "includes": ["fetch.py", "post.py", "auth.py"],
            "use_for": ["Weather APIs", "REST APIs", "GraphQL", "Webhooks"]
        },
        "file-processor": {
            "icon": "📁",
            "name": "File Processor", 
            "description": "Process files: extract, convert, merge, and transform documents.",
            "includes": ["extract.py", "convert.py", "batch.py"],
            "use_for": ["PDFs", "Images", "Documents", "Archives"]
        },
        "data-transformer": {
            "icon": "🔄",
            "name": "Data Transformer",
            "description": "Transform data between formats with validation and mapping.",
            "includes": ["transform.py", "validate.py", "map.py"],
            "use_for": ["JSON ↔ CSV", "XML parsing", "Data cleaning", "Schema mapping"]
        },
        "automation": {
            "icon": "⚙️",
            "name": "Automation",
            "description": "Automate repetitive tasks with scheduling and notifications.",
            "includes": ["schedule.py", "task.py", "notify.py"],
            "use_for": ["Scheduled jobs", "Batch processing", "Reminders", "Monitoring"]
        },
        "integration": {
            "icon": "🔌",
            "name": "Integration",
            "description": "Integrate with external services and synchronize data.",
            "includes": ["connect.py", "sync.py", "webhook.py"],
            "use_for": ["Slack/Discord", "GitHub", "Databases", "Cloud storage"]
        },
        "custom": {
            "icon": "🎨",
            "name": "Custom",
            "description": "Start from scratch and build something unique.",
            "includes": ["main.py"],
            "use_for": ["Anything you can imagine!"]
        }
    }
    
    for template_id, template in templates.items():
        with st.expander(f"{template['icon']} {template['name']}"):
            st.markdown(f"**{template['description']}**")
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("**Includes:**")
                for script in template['includes']:
                    st.markdown(f"- `{script}`")
            
            with col2:
                st.markdown("**Great for:**")
                for use in template['use_for']:
                    st.markdown(f"- {use}")
            
            if st.button(f"Use {template['name']} Template", key=f"tpl_{template_id}"):
                st.session_state['create_template'] = template_id
                st.switch_page("Create Tool")

# Settings Page
elif "⚙️ Settings" in page:
    st.markdown('<p class="main-header">⚙️ Settings</p>', unsafe_allow_html=True)
    
    st.markdown("### 📁 Directories")
    st.markdown(f"**Skills Directory:** `{SKILLS_DIR}`")
    st.markdown(f"**Mission Control:** `{MISSION_CONTROL_DIR}`")
    
    st.markdown("---")
    
    st.markdown("### 🔧 Actions")
    
    col1, col2 = st.columns(2)
    
    with col1:
        if st.button("📂 Open Skills Folder"):
            if SKILLS_DIR.exists():
                os.startfile(str(SKILLS_DIR))
            else:
                st.error("Skills directory not found!")
    
    with col2:
        if st.button("🔄 Reload Page"):
            st.rerun()
    
    st.markdown("---")
    
    st.markdown("### ℹ️ About")
    st.markdown("""
    **Mission Control** is your personal tool factory for OpenClaw.
    
    Create custom skills with:
    - Pre-built templates
    - Automatic structure generation
    - Integrated documentation
    - Easy deployment
    
    Version: 1.0.0
    Built with: Streamlit + Python
    """)

# Footer
st.markdown("---")
st.markdown("<p style='text-align: center; color: gray;'>🚀 Mission Control - Build anything</p>", unsafe_allow_html=True)
