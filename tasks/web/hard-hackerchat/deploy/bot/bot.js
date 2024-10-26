const child_process = require('node:child_process');
const crypto = require("node:crypto");
const process = require('node:process');

const puppeteer = require("puppeteer");

const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false,
});
readline.ask = str => new Promise(resolve => readline.question(str, resolve));

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

const TIMEOUT = process.env.TIMEOUT || 300 * 1000;
const SLEEP_TIME = process.env.SLEEP_TIME || 180 * 1000;
const CHAT_URL = process.env.CHAT_URL || 'http://localhost:8080/';

const POW_BITS = process.env.POW_BITS || 28;

const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;

async function pow() {
    const nonce = crypto.randomBytes(8).toString('hex');

    console.log('[*] Please solve PoW:');
    console.log(`hashcash -q -mb${POW_BITS} ${nonce}`);

    const answer = await readline.ask('> ');

    const check = child_process.spawnSync(
        '/usr/bin/hashcash',
        ['-q', '-f', '/tmp/bot/hashcash.sdb', `-cdb${POW_BITS}`, '-r', nonce, answer],
    );
    const correct = (check.status === 0);

    if (!correct) {
        console.log('[-] Incorrect.');
        process.exit(0);
    }

    console.log('[+] Correct.');
}

async function visit(url) {
    console.log(`visiting ${url}`)
    const params = {
        browser: 'chrome',
        args: [
            '--no-sandbox',
            '--disable-gpu',
            '--disable-extensions',
            '--js-flags=--jitless',
        ],
        headless: true,
    };

    const browser = await puppeteer.launch(params);
    const context = await browser.createBrowserContext();

    const pid = browser.process().pid;

    const shutdown = async () => {
        await context.close();
        await browser.close();

        try {
            process.kill(pid, 'SIGKILL');
        } catch(_) { }

        process.exit(0);
    };

    console.log(`opening page`)
    const page1 = await context.newPage();
    await page1.setViewport({
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
      isMobile: false
    });

    console.log(`opening ${CHAT_URL}`)
    await page1.goto(`${CHAT_URL}`);
    const inputs = await page1.$$('input');
    await inputs[0].type('admin');
    await inputs[1].type(ADMIN_PASSWORD);
    const button = await page1.$('button');
    await button.click();

    console.log(`saving screenshot`)
    await page1.screenshot({path: '/vol/screen.png'})
    await sleep(SLEEP_TIME);
}

async function main() {
    if (POW_BITS > 0) {
        await pow();
    }

    console.log('[?] Please input URL:');
    const url = await readline.ask('> ');

    console.log('[+] OK, it doesn\'t matter anyways :)');

    readline.close()
    // process.stdin.end();
    // process.stdout.end();

    await visit(url);

    await sleep(TIMEOUT);
}

main();
