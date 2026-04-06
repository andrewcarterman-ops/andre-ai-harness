//! Memory Classifier
//! 
//! Classifies messages by importance for selective preservation

/// Importance level for memory classification
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Importance {
    /// Must preserve exactly: decisions, errors, security events
    Critical,
    /// Should preserve: key insights, patterns learned
    Important,
    /// Nice to have: context, explanations
    Reference,
    /// Can discard: greetings, confirmations
    Trivial,
}

impl Importance {
    /// Get numeric priority (higher = more important)
    pub fn priority(&self) -> u8 {
        match self {
            Self::Critical => 4,
            Self::Important => 3,
            Self::Reference => 2,
            Self::Trivial => 1,
        }
    }

    /// Check if this should be synced to Second Brain
    pub fn should_sync(&self) -> bool {
        matches!(self, Self::Critical | Self::Important)
    }

    /// Check if this should update MEMORY.md
    pub fn should_update_memory_md(&self) -> bool {
        matches!(self, Self::Critical)
    }

    /// Check if this should be preserved during compaction
    pub fn should_preserve(&self) -> bool {
        matches!(self, Self::Critical | Self::Important)
    }

    /// Get string representation
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Critical => "critical",
            Self::Important => "important",
            Self::Reference => "reference",
            Self::Trivial => "trivial",
        }
    }
}

impl Default for Importance {
    fn default() -> Self {
        Self::Reference
    }
}

impl std::fmt::Display for Importance {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.as_str())
    }
}

/// Classified memory entries
#[derive(Debug, Clone, Default)]
pub struct ClassifiedMemory<T> {
    /// Must preserve exactly
    pub critical: Vec<T>,
    /// Should preserve
    pub important: Vec<T>,
    /// Nice to have
    pub reference: Vec<T>,
    /// Can discard
    pub trivial: Vec<T>,
}

impl<T> ClassifiedMemory<T> {
    /// Create empty classified memory
    pub fn new() -> Self {
        Self {
            critical: Vec::new(),
            important: Vec::new(),
            reference: Vec::new(),
            trivial: Vec::new(),
        }
    }

    /// Add item with importance
    pub fn add(&mut self, item: T, importance: Importance) {
        match importance {
            Importance::Critical => self.critical.push(item),
            Importance::Important => self.important.push(item),
            Importance::Reference => self.reference.push(item),
            Importance::Trivial => self.trivial.push(item),
        }
    }

    /// Get all important items (critical + important)
    pub fn important_items(&self) -> Vec<&T> {
        self.critical.iter()
            .chain(self.important.iter())
            .collect()
    }

    /// Get total count
    pub fn total_count(&self) -> usize {
        self.critical.len() + self.important.len() + self.reference.len() + self.trivial.len()
    }

    /// Check if empty
    pub fn is_empty(&self) -> bool {
        self.total_count() == 0
    }
}

/// Memory classifier using heuristic patterns
#[derive(Debug, Clone)]
pub struct MemoryClassifier {
    patterns: ClassificationPatterns,
}

impl MemoryClassifier {
    /// Create new classifier
    pub fn new() -> Self {
        Self {
            patterns: ClassificationPatterns::new(),
        }
    }

    /// Classify content by importance
    pub fn classify(&self, role: &str, content: &str) -> Importance {
        let lower = content.to_lowercase();

        // Critical patterns
        if self.patterns.is_critical(&lower) {
            return Importance::Critical;
        }

        // Important patterns
        if self.patterns.is_important(&lower) {
            return Importance::Important;
        }

        // Trivial patterns
        if self.patterns.is_trivial(&lower, role) {
            return Importance::Trivial;
        }

        // Default based on role
        match role {
            "system" => Importance::Reference,
            "user" => Importance::Reference,
            "assistant" => Importance::Reference,
            "tool" => Importance::Important, // Tool results are usually important
            _ => Importance::Reference,
        }
    }

    /// Classify multiple messages
    pub fn classify_messages(&self, messages: &[(String, String)]) -> ClassifiedMemory<(String, String)> {
        let mut classified = ClassifiedMemory::new();

        for (role, content) in messages {
            let importance = self.classify(role, content);
            classified.add((role.clone(), content.clone()), importance);
        }

        classified
    }
}

impl Default for MemoryClassifier {
    fn default() -> Self {
        Self::new()
    }
}

/// Classification patterns
#[derive(Debug, Clone)]
pub struct ClassificationPatterns;

impl ClassificationPatterns {
    /// Create new patterns
    pub fn new() -> Self {
        Self
    }

    /// Check if content is critical
    pub fn is_critical(&self, content: &str) -> bool {
        let patterns = [
            "error:",
            "exception:",
            "failed",
            "failure",
            "security",
            "vulnerability",
            "cve-",
            "permission denied",
            "unauthorized",
            "data loss",
            "corruption",
            "decided to",
            "decision:",
            "conclusion:",
            "critical",
            "emergency",
            "panic:",
            "fatal",
        ];

        patterns.iter().any(|p| content.contains(p))
    }

    /// Check if content is important
    pub fn is_important(&self, content: &str) -> bool {
        let patterns = [
            "lesson learned",
            "best practice",
            "pattern:",
            "key insight",
            "solution:",
            "workaround",
            "optimization",
            "improvement",
            "fixed",
            "resolved",
            "completed",
            "success",
            "warning:",
            "deprecated",
            "breaking change",
        ];

        patterns.iter().any(|p| content.contains(p))
    }

    /// Check if content is trivial
    pub fn is_trivial(&self, content: &str, role: &str) -> bool {
        // Short messages are often trivial
        if content.len() < 30 && role == "user" {
            return true;
        }

        let patterns = [
            "hello",
            "hi",
            "hey",
            "thanks",
            "thank you",
            "got it",
            "understood",
            "ok",
            "okay",
            "please",
            "could you",
            "yes",
            "no",
            "maybe",
            "sure",
            "alright",
            "bye",
            "goodbye",
        ];

        let trimmed = content.trim().to_lowercase();
        patterns.iter().any(|p| trimmed == *p)
    }
}

impl Default for ClassificationPatterns {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_importance_priority() {
        assert!(Importance::Critical.priority() > Importance::Important.priority());
        assert!(Importance::Important.priority() > Importance::Reference.priority());
        assert!(Importance::Reference.priority() > Importance::Trivial.priority());
    }

    #[test]
    fn test_importance_sync() {
        assert!(Importance::Critical.should_sync());
        assert!(Importance::Important.should_sync());
        assert!(!Importance::Reference.should_sync());
        assert!(!Importance::Trivial.should_sync());
    }

    #[test]
    fn test_classify_critical() {
        let classifier = MemoryClassifier::new();
        
        assert_eq!(
            classifier.classify("assistant", "Error: failed to connect to database"),
            Importance::Critical
        );
        
        assert_eq!(
            classifier.classify("assistant", "Security vulnerability detected"),
            Importance::Critical
        );
        
        assert_eq!(
            classifier.classify("assistant", "Decision: we will use PostgreSQL"),
            Importance::Critical
        );
    }

    #[test]
    fn test_classify_important() {
        let classifier = MemoryClassifier::new();
        
        assert_eq!(
            classifier.classify("assistant", "Key insight: caching improves performance"),
            Importance::Important
        );
        
        assert_eq!(
            classifier.classify("assistant", "Solution: use connection pooling"),
            Importance::Important
        );
    }

    #[test]
    fn test_classify_trivial() {
        let classifier = MemoryClassifier::new();
        
        assert_eq!(
            classifier.classify("user", "ok"),
            Importance::Trivial
        );
        
        assert_eq!(
            classifier.classify("user", "thanks"),
            Importance::Trivial
        );
        
        assert_eq!(
            classifier.classify("user", "hello"),
            Importance::Trivial
        );
    }

    #[test]
    fn test_classified_memory() {
        let mut classified = ClassifiedMemory::new();
        
        classified.add("msg1", Importance::Critical);
        classified.add("msg2", Importance::Important);
        classified.add("msg3", Importance::Trivial);
        
        assert_eq!(classified.total_count(), 3);
        assert_eq!(classified.critical.len(), 1);
        assert_eq!(classified.important.len(), 1);
        assert_eq!(classified.trivial.len(), 1);
        
        let important = classified.important_items();
        assert_eq!(important.len(), 2);
    }

    #[test]
    fn test_classify_messages() {
        let classifier = MemoryClassifier::new();
        let messages = vec![
            ("user".to_string(), "Hello".to_string()),
            ("assistant".to_string(), "Error: something went wrong".to_string()),
            ("user".to_string(), "ok".to_string()),
        ];
        
        let classified = classifier.classify_messages(&messages);
        
        assert_eq!(classified.trivial.len(), 2); // "Hello" and "ok"
        assert_eq!(classified.critical.len(), 1); // Error message
    }
}
