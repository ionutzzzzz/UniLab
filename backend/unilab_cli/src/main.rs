use unilab_core::{run_code, Evaluator, parse_unilab};
use std::env;
use std::fs;
use std::path::Path;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: unilab_cli <script.m>");
        return Ok(());
    }

    let file_path = &args[1];
    let content = fs::read_to_string(file_path)?;
    let parent_dir = Path::new(file_path).parent().unwrap_or(Path::new("."));

    println!("Executing: {}", file_path);
    
    // Manual execution to set search paths
    let program = parse_unilab(&content)?;
    let mut evaluator = Evaluator::new();
    evaluator.search_paths.push(parent_dir.to_path_buf());
    
    match evaluator.eval_program(&program) {
        Ok(result) => {
            println!("Execution finished.");
            if result != unilab_core::Value::Void {
                println!("Result: {}", result);
            }
            if !evaluator.plots.is_empty() {
                println!("Generated {} plots.", evaluator.plots.len());
                for (i, plot) in evaluator.plots.iter().enumerate() {
                    println!("Plot {}: {:?}", i + 1, plot);
                }
            }
        }
        Err(e) => {
            eprintln!("Execution Error: {}", e);
        }
    }

    Ok(())
}
