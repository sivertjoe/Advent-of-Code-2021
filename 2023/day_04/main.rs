use std::collections::*;

fn parse(input: &[String]) -> Vec<(HashSet<usize>, HashSet<usize>)> {
    input
        .iter()
        .map(|line| {
            let (_, line) = line.split_once(": ").unwrap();
            let (winning, mine) = line.split_once(" | ").unwrap();

            (
                winning
                    .split_ascii_whitespace()
                    .map(|w| w.parse::<usize>().unwrap())
                    .collect::<HashSet<_>>(),
                mine.split_ascii_whitespace()
                    .map(|w| w.parse::<usize>().unwrap())
                    .collect::<HashSet<_>>(),
            )
        })
        .collect()
}

fn calc_score(winning: &HashSet<usize>, mine: &HashSet<usize>) -> usize {
    let mut sum = 0;
    for num in mine {
        if winning.contains(&num) {
            if sum > 0 {
                sum *= 2;
            } else {
                sum += 1;
            }
        }
    }
    sum
}

fn mat(winning: &HashSet<usize>, mine: &HashSet<usize>) -> usize {
    let mut sum = 0;
    for num in mine {
        if winning.contains(&num) {
            sum += 1;
        }
    }
    sum
}

fn task_one(input: &[String]) -> usize {
    let p = parse(input);

    let mut sum = 0;
    for (winning, mine) in p {
        sum += calc_score(&winning, &mine);
    }
    sum
}

fn task_two(input: &[String]) -> usize {
    let p = parse(input);

    let mut vec = vec![1; p.len()];

    for (id, (winning, mine)) in p.into_iter().enumerate() {
        let id = id + 1;
        let num_matches = mat(&winning, &mine);
        for i in id..id + num_matches {
            vec[i] += vec[id - 1];
        }
    }
    vec.into_iter().sum()
}

fn main() {
    let input = read_input(get_input_file());
    time(Task::One, task_one, &input);
    time(Task::Two, task_two, &input);
}

fn read_input<P>(path: P) -> Vec<String>
where
    P: AsRef<std::path::Path>,
{
    std::fs::read_to_string(path)
        .unwrap()
        .lines()
        .map(String::from)
        .collect()
}

enum Task {
    One,
    Two,
}

fn time<F, T, U>(task: Task, f: F, arg: T)
where
    F: Fn(T) -> U,
    U: std::fmt::Display,
{
    let t = std::time::Instant::now();
    let res = f(arg);
    let elapsed = t.elapsed();
    let fmt = std::env::var("TASKUNIT").unwrap_or("ms".to_owned());

    let (u, elapsed) = match fmt.as_str() {
        "ms" => ("ms", elapsed.as_millis()),
        "ns" => ("ns", elapsed.as_nanos()),
        "us" => ("μs", elapsed.as_micros()),
        "s" => ("s", elapsed.as_secs() as u128),
        _ => panic!("unsupported time format"),
    };

    match task {
        Task::One => {
            println!("({}{u})\tTask one: \x1b[0;34;34m{}\x1b[0m", elapsed, res);
        }
        Task::Two => {
            println!("({}{u})\tTask two: \x1b[0;33;10m{}\x1b[0m", elapsed, res);
        }
    };
}

fn get_input_file() -> String {
    std::env::args()
        .nth(1)
        .unwrap_or_else(|| "input".to_string())
}
