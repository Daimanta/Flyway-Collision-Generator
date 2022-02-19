const std = @import("std");

const clap = @import("clap.zig");
const version = @import("version.zig");

const crc32 = std.hash.crc.Crc32;

const Allocator = std.mem.Allocator;
var default_allocator = std.heap.page_allocator;

const help_message = 
\\Usage: crc-collision [OPTION] FILE 
\\ Generates an SQL file with the same CRC32 checksum as the target file.
\\
\\ If arguments are possible, they are mandatory unless specified otherwise.
\\        -h, --help              Display this help and exit.
\\        -c, --comment           Produces a single commented line (default)
\\
;

pub fn main() !void {
    const params = comptime [_]clap.Param(clap.Help){
        clap.parseParam("-c, --comment") catch unreachable,
        clap.parseParam("-h, --help") catch unreachable,
        clap.parseParam("<STR>") catch unreachable,
    };
    
    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        diag.report(std.io.getStdOut().writer(), err) catch {};
        return;
    };
    defer args.deinit();
    
    if (args.flag("--help")) {
        print(help_message, .{});
        std.os.exit(0);
    }
    
    const positionals = args.positionals();

    if (positionals.len != 1) {
        print("One file can and must be supplied. Exiting\n", .{});
        std.os.exit(1);
    }
    
    const file = std.fs.cwd().openFile(positionals[0], .{.read = true}) catch {
        print("Could not read file. Exiting\n", .{});
        std.os.exit(1);
    };
    defer file.close();
    
    var crc32_state = crc32.init();
    const bytes = try file.readToEndAlloc(default_allocator, 1 << 30);
    var tokens = std.mem.tokenize(u8, bytes, "\n");
    while (tokens.next()) |line| {
        if (line.len == 0) {
            continue;
        } else if (line[line.len - 1] == '\r') {
            crc32_state.update(line[0..line.len - 1]);
        } else {
            crc32_state.update(line);
        }
    }
    const target_hash = crc32_state.final();
    _ = target_hash;
    
    const first_value: u8 = 33;
    const last_value: u8 = 126;
    var test_state = [_]u8{'-', '-', ' ', 0, 0, 0, 0, 0, 0};
    
    var j0 = first_value;
    var j1 = first_value;
    var j2 = first_value;
    var j3 = first_value;
    var j4 = first_value;
    var j5 = first_value;
    {    
        @setRuntimeSafety(false);
        while (j0 <= last_value): (j0 += 1) {
            j1 = first_value;
            while (j1 <= last_value): (j1 += 1) {
                j2 = first_value;
                while (j2 <= last_value): (j2 += 1) {
                    j3 = first_value;
                    while (j3 <= last_value): (j3 += 1) {
                        j4 = first_value;
                        while (j4 <= last_value): (j4 += 1) {
                            j5 = first_value;
                            while (j5 <= last_value): (j5 += 1) {
                                test_state = [_]u8{'-', '-', ' ', j0, j1, j2, j3, j4, j5};
                                const calc_val = crc32.hash(test_state[0..]);
                                if (calc_val == target_hash) {
                                    print("{s}\n", .{test_state});
                                    std.os.exit(0);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


pub fn print(comptime format_string: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(format_string, args) catch return;
}
