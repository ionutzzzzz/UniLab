use std::env;
use std::fs;
use std::path::Path;
use unilab_core::{parse_unilab, Evaluator, Value};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: unilab_cli <script.m>");
        return;
    }

    let file_path = &args[1];
    let content = match fs::read_to_string(file_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error reading file {}: {}", file_path, e);
            std::process::exit(1);
        }
    };
    let parent_dir = Path::new(file_path).parent().unwrap_or(Path::new("."));

    println!("Executing: {}", file_path);

    let program = match parse_unilab(&content) {
        Ok(p) => p,
        Err(e) => {
            eprintln!("Parse Error: {}", e);
            std::process::exit(1);
        }
    };

    let mut evaluator = Evaluator::new();
    evaluator.search_paths.push(parent_dir.to_path_buf());

    match evaluator.eval_program(&program) {
        Ok(result) => {
            if !evaluator.stdout.is_empty() {
                print!("{}", evaluator.stdout);
            }
            println!("Execution finished.");
            if result != Value::Void {
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
            if !evaluator.stdout.is_empty() {
                print!("{}", evaluator.stdout);
            }
            eprintln!("Execution Error: {}", e);
            std::process::exit(1);
        }
    }
}
