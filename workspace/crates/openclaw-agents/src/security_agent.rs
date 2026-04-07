//! Security Analysis Agent
//! 
//! Scans code for security issues.

use crate::{Agent, AgentConfig, AgentOutput};
use async_trait::async_trait;
use anyhow::Result;

pub struct SecurityAgent {
    config: AgentConfig,
}

impl SecurityAgent {
    pub fn new() -> Self {
        Self {
            config: AgentConfig {
                name: "security".to_string(),
                ..Default::default()
            },
        }
    }
}

#[async_trait]
impl Agent for SecurityAgent {
    fn name(&self) -> &str {
        &self.config.name
    }
    
    fn config(&self) -> &AgentConfig {
        &self.config
    }
    
    async fn execute(&self, task: &str, _context: &str) -> Result<AgentOutput> {
        let output = format!(
            "## Security Analysis\n\nTask: {}\n\nSecurity Scan: (Placeholder)\n",
            task
        );
        
        Ok(AgentOutput::new(self.name(), output))
    }
}
