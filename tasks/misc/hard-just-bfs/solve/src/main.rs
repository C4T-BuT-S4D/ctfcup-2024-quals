use clap::Parser;
use image::GenericImageView;
use image::ImageReader;
use image::Rgb;
use image::RgbImage;
use serde::Deserialize;
use std::cmp;
use std::collections::HashMap;
use std::collections::HashSet;
use std::collections::VecDeque;
use std::fs;
use std::io::Cursor;
use std::string::String;
use std::vec::Vec;
use tempfile::Builder;
//use tokio::fs;

const BLUE: Rgb<u8> = Rgb::<u8>([0x1f, 0x78, 0xb4]);
const BLACK: Rgb<u8> = Rgb::<u8>([0x23, 0x23, 0x23]);
const BLUE_THRESHOLD: u32 = 150;
const BLACK_THRESHOLD: u32 = 150;
const BLUE_SET_SIZE_THRESHOLD: usize = 4000;
const ALPHABET: &str = "ABCDEFGHIJKLMNOPQRS";

fn diff(a: Rgb<u8>, b: Rgb<u8>) -> u32 {
    unsafe {
        u32::try_from(
            (i32::from(a[0]) - i32::from(b[0])).abs()
                + (i32::from(a[1]) - i32::from(b[1])).abs()
                + (i32::from(a[2]) - i32::from(b[2])).abs(),
        )
        .unwrap_unchecked()
    }
}

fn find_set_bfs(
    img: &RgbImage,
    color: Rgb<u8>,
    threshold: u32,
    visited: &mut [Vec<bool>],
    set: &mut Vec<(u32, u32)>,
    x: u32,
    y: u32,
) {
    let mut q: VecDeque<(u32, u32)> = VecDeque::new();
    q.push_back((x, y));
    while !q.is_empty() {
        let (x, y) = q.pop_front().unwrap();

        if unsafe {
            *visited
                .get_unchecked(usize::try_from(x).unwrap_unchecked())
                .get_unchecked(usize::try_from(y).unwrap_unchecked())
        } {
            continue;
        }
        if unsafe { diff(img.unsafe_get_pixel(x, y), color) } > threshold {
            continue;
        }

        set.push((x, y));
        unsafe {
            *visited
                .get_unchecked_mut(usize::try_from(x).unwrap_unchecked())
                .get_unchecked_mut(usize::try_from(y).unwrap_unchecked()) = true;
        };
        for yd in -1..2 {
            let new_y = unsafe { i32::try_from(y).unwrap_unchecked() } + yd;
            if 0 > new_y || new_y >= unsafe { i32::try_from(img.height()).unwrap_unchecked() } {
                continue;
            }
            for xd in -1..2 {
                let new_x = unsafe { i32::try_from(x).unwrap_unchecked() } + xd;
                if 0 > new_x || new_x >= unsafe { i32::try_from(img.width()).unwrap_unchecked() } {
                    continue;
                }
                unsafe {
                    q.push_back((
                        u32::try_from(new_x).unwrap_unchecked(),
                        u32::try_from(new_y).unwrap_unchecked(),
                    ));
                }
            }
        }
    }
}

fn ocr(img: RgbImage) -> String {
    let mut img = img;
    for pixel in img.pixels_mut() {
        if diff(*pixel, BLUE) <= BLUE_THRESHOLD {
            *pixel = Rgb::<u8>([255, 255, 255]);
        }
    }

    let mut black_sets: Vec<Vec<(u32, u32)>> = vec![];
    let mut visited: Vec<Vec<bool>> =
        vec![vec![false; img.height().try_into().unwrap()]; img.width().try_into().unwrap()];

    for y in 0..img.height() {
        for x in 0..img.width() {
            let mut set: Vec<(u32, u32)> = vec![];
            find_set_bfs(&img, BLACK, BLACK_THRESHOLD, &mut visited, &mut set, x, y);
            if !set.is_empty() {
                black_sets.push(set);
            }
        }
    }

    let main_set = black_sets
        .into_iter()
        .max_by(|a, b| a.len().cmp(&b.len()))
        .unwrap();

    let mut min_x = main_set[0].0;
    let mut min_y = main_set[0].1;
    let mut max_x = main_set[0].0;
    let mut max_y = main_set[0].1;
    for (x, y) in main_set.iter() {
        min_x = cmp::min(min_x, *x);
        min_y = cmp::min(min_y, *y);
        max_x = cmp::max(max_x, *x);
        max_y = cmp::max(max_y, *y);
    }
    let img = img
        .view(min_x, min_y, max_x - min_x, max_y - min_y)
        .to_image();

    let img_file = Builder::new().suffix(".png").tempfile().unwrap();
    let path = img_file.path();
    img.save(path).unwrap();

    let res = subprocess::Exec::cmd("gocr")
        .arg("-c")
        .arg(ALPHABET)
        .arg(path)
        .stdout(subprocess::Redirection::Pipe)
        .capture()
        .unwrap()
        .stdout_str();

    for c in res.to_uppercase().chars() {
        if ALPHABET.contains(c) {
            return c.to_string();
        }
    }

    img.save("fail.png").unwrap();
    std::panic!("ocr failed");
}

fn parse_image_to_graph(img: &RgbImage) -> HashMap<String, Vec<String>> {
    let mut visited: Vec<Vec<bool>> =
        vec![vec![false; img.height().try_into().unwrap()]; img.width().try_into().unwrap()];
    let mut blue_sets: Vec<Vec<(u32, u32)>> = vec![];
    let mut black_sets: Vec<Vec<(u32, u32)>> = vec![];
    for y in 0..img.height() {
        for x in 0..img.width() {
            let mut set: Vec<(u32, u32)> = vec![];
            find_set_bfs(img, BLUE, BLUE_THRESHOLD, &mut visited, &mut set, x, y);
            if !set.is_empty() {
                blue_sets.push(set);
            } else {
                find_set_bfs(img, BLACK, BLACK_THRESHOLD, &mut visited, &mut set, x, y);
                if !set.is_empty() {
                    black_sets.push(set);
                }
            }
        }
    }

    //println!("{}", blue_sets.len());
    let mut point_to_letter: HashMap<(u32, u32), String> = HashMap::new();
    for set in blue_sets.iter() {
        if set.len() < BLUE_SET_SIZE_THRESHOLD {
            continue;
        }
        let mut min_x = set[0].0;
        let mut min_y = set[0].1;
        let mut max_x = set[0].0;
        let mut max_y = set[0].1;
        for (x, y) in set.iter() {
            min_x = cmp::min(min_x, *x);
            min_y = cmp::min(min_y, *y);
            max_x = cmp::max(max_x, *x);
            max_y = cmp::max(max_y, *y);
        }

        let sub_img = img
            .view(min_x, min_y, max_x - min_x, max_y - min_y)
            .to_image();
        let v = ocr(sub_img);

        for point in set {
            point_to_letter.insert(*point, v.clone());
        }
    }

    let mut graph: HashMap<String, Vec<String>> = HashMap::new();
    for set in black_sets.iter() {
        let mut connected_vertices: HashSet<String> = HashSet::new();
        for (x, y) in set.iter() {
            for yd in -2..3 {
                let new_y = i32::try_from(*y).unwrap() + yd;
                if 0 > new_y || new_y >= i32::try_from(img.height()).unwrap() {
                    continue;
                }
                for xd in -2..3 {
                    let new_x = i32::try_from(*x).unwrap() + xd;
                    if 0 > new_x || new_x >= i32::try_from(img.width()).unwrap() {
                        continue;
                    }
                    if let Some(v) = point_to_letter
                        .get(&(u32::try_from(new_x).unwrap(), u32::try_from(new_y).unwrap()))
                    {
                        connected_vertices.insert(v.to_string());
                    }
                }
            }
        }

        assert!(connected_vertices.len() < 3);
        if connected_vertices.len() == 2 {
            let connected_vertices_list: Vec<String> = connected_vertices.into_iter().collect();
            graph
                .entry(connected_vertices_list[0].clone())
                .or_default()
                .push(connected_vertices_list[1].clone());
            graph
                .entry(connected_vertices_list[1].clone())
                .or_default()
                .push(connected_vertices_list[0].clone());
        }
    }

    graph
}

fn bfs(graph: &HashMap<String, Vec<String>>, start: &str, target: &str) -> Vec<String> {
    let mut visited: HashSet<String> = HashSet::new();
    let mut q: VecDeque<(String, Vec<String>)> = VecDeque::new();

    q.push_back((start.to_string(), vec![start.to_string()]));

    while !q.is_empty() {
        let (v, mut path) = q.pop_front().unwrap();

        if visited.contains(&v) {
            continue;
        }
        visited.insert(v.clone());

        if v == target {
            return path;
        }
        for u in graph.get(&v.to_string()).unwrap() {
            path.push(u.to_string());
            q.push_back((u.to_string(), path.clone()));
            path.pop();
        }
    }

    panic!("path not found")
}

#[derive(Parser)]
struct Cli {
    url: String,
}

#[derive(Deserialize, Debug)]
struct Params {
    source: String,
    target: String,
}

#[derive(Deserialize, Debug)]
#[allow(dead_code)]
struct Response {
    status: String,
    flag: Option<String>,
    reason: Option<String>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Cli::parse();
    let client = reqwest::Client::builder().cookie_store(true).build()?;

    for _ in 0..150 {
        let params = client
            .get(format!("{}/params", args.url))
            .send()
            .await?
            .json::<Params>()
            .await?;

        let img_bytes = client
            .get(format!("{}/image", args.url))
            .send()
            .await?
            .bytes()
            .await?;
        fs::write("current.png", &img_bytes).unwrap();
        let img = ImageReader::new(Cursor::new(img_bytes))
            .with_guessed_format()
            .unwrap()
            .decode()
            .unwrap()
            .into_rgb8();

        let g = parse_image_to_graph(&img);
        let path = bfs(&g, &params.source, &params.target);
        let response = client
            .post(format!("{}/submit", args.url))
            .json(&path)
            .send()
            .await?
            .json::<Response>()
            .await?;

        dbg!(response);
    }

    Ok(())
}
