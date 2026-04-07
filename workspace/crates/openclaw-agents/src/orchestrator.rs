//! Sequential workflow orchestrator
//! 
//! Agents are executed one after another (not parallel)
//! to respect hardware constraints.

use crate::{Agent, AgentOutput};
use anyhow::Result;
use std::sync::Arc;
use tracing::{info, warn};

/// A workflow step
pub struct WorkflowStep {
    pub name: String,
    pub agent: Arc<dyn Agent>,
    pub condition: Option<Box<dyn Fn(&[AgentOutput]) -> bool + Send + Sync>>,
}

/// Sequential workflow orchestrator
pub struct Orchestrator {
    name: String,
    steps: Vec<WorkflowStep>,
    results: Vec<AgentOutput>,
}

/// Workflow definition
pub struct Workflow {
    pub name: String,
    pub description: String,
    pub steps: Vec<String>, // Agent names in order
}

impl Orchestrator {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            steps: Vec::new(),
            results: Vec::new(),
        }
    }
    
    /// Add a step to the workflow
    pub fn add_step(mut self, name: impl Into<String>, agent: Arc<dyn Agent>) -> Self {
        self.steps.push(WorkflowStep {
            name: name.into(),
            agent,
            condition: None,
        });
        self
    }
    
    /// Add a conditional step
    pub fn add_step_if(
        mut self,
        name: impl Into<String>,
        agent: Arc<dyn Agent>,
        condition: impl Fn(&[AgentOutput]) -> bool + Send + Sync + 'static
    ) -> Self {
        self.steps.push(WorkflowStep {
            name: name.into(),
            agent,
            condition: Some(Box::new(condition)),
        });
        self
    }
    
    /// Execute the workflow sequentially
    pub async fn run(&mut self, initial_task: &str, context: &str) -> Result<Vec<AgentOutput>> {
        info!("Starting workflow: {}", self.name);
        
        let mut current_task = initial_task.to_string();
        
        for (i, step) in self.steps.iter().enumerate() {
            // Check condition if present
            if let Some(ref condition) = step.condition {
                if !condition(&self.results) {
                    info!("Skipping step {} (condition not met)", step.name);
                    continue;
                }
            }
            
            info!("Step {}/{}: {} ({})", 
                i + 1, self.steps.len(), step.name, step.agent.name());
            
            // Execute agent
            match step.agent.execute(&current_task, context).await {
                Ok(output) => {
                    info!("Step {} completed successfully", step.name);
                    current_task = format!("{}\n\nPrevious result:\n{}", 
                        current_task, output.content);
                    self.results.push(output);
                }
                Err(e) => {
                    warn!("Step {} failed: {}", step.name, e);
                    return Err(e);
                }
            }
        }
        
        info!("Workflow {} completed with {} results", self.name, self.results.len());
        Ok(self.results.clone())
    }
    
    /// Get results so far
    pub fn results(&self) -> &[AgentOutput] {
        &self.results
    }
    
    /// Clear results
    pub fn clear(&mut self) {
        self.results.clear();
    }
}
