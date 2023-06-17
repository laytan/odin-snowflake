// Snowflake ID's are a form of unique identifiers developed originally by/for Twitter.
// ID's are sortable (by creation time), store the generation time in them (no need for a created_at field in a DB),
// are a length of 13 bytes in base32 and 100% unique if used correctly.
// Learn more here: https://en.wikipedia.org/wiki/Snowflake_ID
package snowflake

import "core:time"
import "core:sync"

ID :: i64

// Generates a snowflake ID, machine_id should be used in distributed systems
// where multiple nodes are running and generating ids that are then used for the same purpose or same data store.
generate :: proc(machine_id: i64 = 1) -> ID {
	assert(machine_id >= 0 && machine_id <= NODE_MAX)

	sync.lock(&mu)
	defer sync.unlock(&mu)

	now := i64(time.duration_milliseconds(time.since(epoch)))

	if now == last_time {
		step = (step + 1) & STEP_MASK
		if step == 0 {
			for now <= last_time {
				now = i64(time.duration_milliseconds(time.since(epoch)))
			}
		}
	} else {
		step = 0
	}

	last_time = now

	return ID((now << TIME_SHIFT) | (machine_id << NODE_SHIFT) | step)
}

// Returns an efficient base32 representation of the ID.
base32 :: proc(id: ID, allocator := context.allocator) -> (str: []byte) {
	str = make([]byte, 13, allocator)
	defer delete(str)
	
	f := id
	if f < 32 {
		str[0] = ENC_TABLE[f]
		return
	}

	for i := 0; f >= 32; i += 1 {
		str[i] = ENC_TABLE[f % 32]
		f /= 32
	}
	str[12] = ENC_TABLE[f]

	for x, y := 0, 12; x < y; x, y = x + 1, y - 1 {
		str[x], str[y] = str[y], str[x]
	}

	return
}

from_base32 :: proc(bs: []byte) -> (id: ID, ok: bool) {
	for b in bs {
		if DEC_TABLE[b] == 0xFF do return
		id = id * 32 + i64(DEC_TABLE[b])
	}
	ok = true
	return
}

// Returns the time that the given snowflake was generated with millisecond precision.
generation_time :: proc(id: ID) -> time.Time {
	ms := (id >> TIME_SHIFT) + EPOCH
	sec := ms / 1000

	rest_ms := ms % 1000
	micro := rest_ms * 1000
	nsec := micro * 1000

	return time.unix(sec, nsec)
}

@(private)
@(init)
init :: proc() {
	for _, i in DEC_TABLE {
		DEC_TABLE[i] = 0xFF
	}

	for _, i in ENC_TABLE {
		DEC_TABLE[ENC_TABLE[i]] = byte(i)
	}
}

@(private)
EPOCH :: 1288834974657
@(private)
NODE_BITS :: 10
@(private)
STEP_BITS :: 12
@(private)
NODE_MAX :: -1 ~ (-1 << NODE_BITS)
@(private)
STEP_MASK :: -1 ~ (-1 << STEP_BITS)
@(private)
TIME_SHIFT :: NODE_BITS + STEP_BITS
@(private)
NODE_SHIFT :: STEP_BITS

@(private)
epoch := time.unix(EPOCH / 1000, (EPOCH % 1000) * 1000000)
@(private)
last_time: i64 = 0
@(private)
mu: sync.Mutex
@(private)
step: i64 = 0

@(private)
ENC_TABLE := [32]byte{
	'y',
	'b',
	'n',
	'd',
	'r',
	'f',
	'g',
	'8',
	'e',
	'j',
	'k',
	'm',
	'c',
	'p',
	'q',
	'x',
	'o',
	't',
	'1',
	'u',
	'w',
	'i',
	's',
	'z',
	'a',
	'3',
	'4',
	'5',
	'h',
	'7',
	'6',
	'9',
}

// Populated in init().
DEC_TABLE: [256]byte
