const tmi = require('tmi.js');
const process = require('process');


// Define configuration options
const opts = {
  identity: {
    username: 'cosmodirty',
    password: 'oauth:62ko1b6uonml3qmw8ov0h62za546fc'
  },
  channels: [
    'cosmodirty'
  ]
};

// Keeps track of current color
var isRed = false;

// Create a client with our options
const client = new tmi.client(opts);

// Register our event handlers (defined below)
client.on('message', onMessageHandler);
client.on('connected', onConnectedHandler);

// Connect to Twitch:
client.connect();

// Called every time a message comes in
function onMessageHandler (target, context, msg, self) {
  if (self) { return; } // Ignore messages from the bot

  // Remove whitespace from chat message
  const commandName = msg.trim();

  // If the command is known, let's execute it
  if (commandName === '!toggle') {
    const num = rollDice();
      if (isRed) {
        client.say(target, `Going back to normal...`);
      } else {
        client.say(target, `Going to red...`);
      }
      isRed = !isRed;
    console.log(`* Executed command`);
    process.kill(Number(process.argv[2]), 'SIGINT');
  } else {
    console.log(`* Unknown command ${commandName}`);
  }
  
}

// Function called when the "dice" command is issued
function rollDice () {
  const sides = 6;
  return Math.floor(Math.random() * sides) + 1;
}

// Called every time the bot connects to Twitch chat
function onConnectedHandler (addr, port) {
  console.log(`* Connected to ${addr}:${port}`);
}
