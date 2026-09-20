import Foundation
import IBUgramKit

struct SeedUserSpec: Sendable {
    var key: String
    var email: String
    var username: String
    var displayName: String
    var bio: String
    var department: String
    var yearOfStudy: Int?
    var red: Double
    var green: Double
    var blue: Double
}

struct SeedPlaceSpec: Sendable {
    var key: String
    var name: String
    var latitude: Double
    var longitude: Double
}

struct SeedSpaceMemberSpec: Sendable {
    var user: String
    var role: SpaceMembership
}

struct SeedSpaceSpec: Sendable {
    var key: String
    var slug: String
    var name: String
    var description: String
    var kind: SpaceKind
    var visibility: SpaceVisibility
    var isOfficial: Bool
    var createdBy: String
    var members: [SeedSpaceMemberSpec]
}

struct SeedEventSpec: Sendable {
    var key: String
    var title: String
    var description: String
    var startOffset: TimeInterval
    var endOffset: TimeInterval
    var place: String
    var host: String
    var space: String?
    var capacity: Int
}

struct SeedPostSpec: Sendable {
    var key: String
    var author: String
    var caption: String
    var space: String? = nil
    var event: String? = nil
    var place: String? = nil
    var altText: String
    var hoursAgo: Double
    var red: Double
    var green: Double
    var blue: Double
    var width: Int
    var height: Int
}

enum DemoSeedDataset {
    static let primaryKey = "amina"

    static let users: [SeedUserSpec] = [
        SeedUserSpec(
            key: "amina",
            email: "amina.hodzic@stu.ibu.edu.ba",
            username: "amina.hodzic",
            displayName: "Amina Hodžić",
            bio: "CS senior · building things for campus · IBU Robotics",
            department: "Information Technologies",
            yearOfStudy: 4,
            red: 0.55, green: 0.10, blue: 0.16
        ),
        SeedUserSpec(
            key: "emir",
            email: "emir.karic@stu.ibu.edu.ba",
            username: "emir.karic",
            displayName: "Emir Karić",
            bio: "Software engineering. Coffee, compilers, campus lawn.",
            department: "Software Engineering",
            yearOfStudy: 3,
            red: 0.10, green: 0.18, blue: 0.35
        ),
        SeedUserSpec(
            key: "lejla",
            email: "lejla.beganovic@stu.ibu.edu.ba",
            username: "lejla.beganovic",
            displayName: "Lejla Beganović",
            bio: "Architecture student. Film club on Thursdays.",
            department: "Architecture",
            yearOfStudy: 2,
            red: 0.72, green: 0.38, blue: 0.28
        ),
        SeedUserSpec(
            key: "haris",
            email: "haris.delalic@stu.ibu.edu.ba",
            username: "haris.delalic",
            displayName: "Haris Delalić",
            bio: "First year, still learning where the cafeteria is.",
            department: "Economics and Management",
            yearOfStudy: 1,
            red: 0.28, green: 0.33, blue: 0.40
        ),
        SeedUserSpec(
            key: "sara",
            email: "sara.petrovic@stu.ibu.edu.ba",
            username: "sara.petrovic",
            displayName: "Sara Petrović",
            bio: "IT · library resident · #ibuweek volunteer",
            department: "Information Technologies",
            yearOfStudy: 3,
            red: 0.40, green: 0.22, blue: 0.38
        ),
        SeedUserSpec(
            key: "nermin",
            email: "nermin.alic@stu.ibu.edu.ba",
            username: "nermin.alic",
            displayName: "Nermin Alić",
            bio: "EE senior. If the lights flicker, that was me.",
            department: "Electrical and Electronics Engineering",
            yearOfStudy: 4,
            red: 0.18, green: 0.45, blue: 0.32
        ),
        SeedUserSpec(
            key: "maja",
            email: "maja.ilic@stu.ibu.edu.ba",
            username: "maja.ilic",
            displayName: "Maja Ilić",
            bio: "International relations. Always on the lawn between classes.",
            department: "International Relations",
            yearOfStudy: 2,
            red: 0.12, green: 0.48, blue: 0.52
        ),
        SeedUserSpec(
            key: "yusuf",
            email: "yusuf.demir@stu.ibu.edu.ba",
            username: "yusuf.demir",
            displayName: "Yusuf Demir",
            bio: "Erasmus in Ilidža. Learning Bosnian one caption at a time.",
            department: "Software Engineering",
            yearOfStudy: 1,
            red: 0.85, green: 0.65, blue: 0.20
        ),
        SeedUserSpec(
            key: "damir",
            email: "damir.kovac@ibu.edu.ba",
            username: "d.kovac",
            displayName: "Prof. Dr. Damir Kovač",
            bio: "Faculty of Engineering and Natural Sciences. Office C-204.",
            department: "Software Engineering",
            yearOfStudy: nil,
            red: 0.08, green: 0.14, blue: 0.28
        ),
        SeedUserSpec(
            key: "elma",
            email: "elma.rizvic@ibu.edu.ba",
            username: "e.rizvic",
            displayName: "Dr. Elma Rizvić",
            bio: "Architecture. Open Day is my favourite week of the year.",
            department: "Architecture",
            yearOfStudy: nil,
            red: 0.62, green: 0.28, blue: 0.22
        ),
        SeedUserSpec(
            key: "jasmin",
            email: "jasmin.hadzic@ibu.edu.ba",
            username: "j.hadzic",
            displayName: "Prof. Jasmin Hadžić",
            bio: "Economics and Management. Bring questions, not excuses.",
            department: "Economics and Management",
            yearOfStudy: nil,
            red: 0.22, green: 0.28, blue: 0.24
        ),
        SeedUserSpec(
            key: "selma",
            email: "selma.basic@ibu.edu.ba",
            username: "s.basic",
            displayName: "Dr. Selma Bašić",
            bio: "Information Technologies. Faculty advisor, IBU Robotics.",
            department: "Information Technologies",
            yearOfStudy: nil,
            red: 0.16, green: 0.32, blue: 0.48
        )
    ]

    static var emails: [String] { users.map(\.email) }

    static let follows: [(String, String)] = [
        ("amina", "emir"), ("amina", "lejla"), ("amina", "sara"),
        ("amina", "nermin"), ("amina", "yusuf"), ("amina", "damir"),
        ("amina", "selma"), ("amina", "elma"),
        ("emir", "amina"), ("emir", "damir"), ("emir", "selma"),
        ("lejla", "amina"), ("lejla", "elma"), ("sara", "amina"),
        ("sara", "selma"), ("nermin", "damir"), ("yusuf", "amina"),
        ("yusuf", "damir"), ("maja", "lejla"), ("haris", "jasmin"),
        ("damir", "selma"), ("selma", "damir")
    ]

    static let places: [SeedPlaceSpec] = [
        SeedPlaceSpec(key: "main", name: "Main building", latitude: 43.8186, longitude: 18.3102),
        SeedPlaceSpec(key: "lawn", name: "Campus lawn", latitude: 43.8182, longitude: 18.3108),
        SeedPlaceSpec(key: "cafeteria", name: "Cafeteria", latitude: 43.8178, longitude: 18.3096),
        SeedPlaceSpec(key: "library", name: "Library", latitude: 43.8189, longitude: 18.3094)
    ]

    static let spaces: [SeedSpaceSpec] = [
        SeedSpaceSpec(
            key: "se",
            slug: "software-engineering",
            name: "Software Engineering",
            description: "Official department Space for SE students and faculty.",
            kind: .department,
            visibility: .public,
            isOfficial: true,
            createdBy: "damir",
            members: [
                SeedSpaceMemberSpec(user: "damir", role: .owner),
                SeedSpaceMemberSpec(user: "selma", role: .moderator),
                SeedSpaceMemberSpec(user: "emir", role: .member),
                SeedSpaceMemberSpec(user: "yusuf", role: .member),
                SeedSpaceMemberSpec(user: "amina", role: .member),
                SeedSpaceMemberSpec(user: "nermin", role: .member)
            ]
        ),
        SeedSpaceSpec(
            key: "robotics",
            slug: "ibu-robotics",
            name: "IBU Robotics",
            description: "Official club. Builds, competitions, and late nights in A-12.",
            kind: .club,
            visibility: .public,
            isOfficial: true,
            createdBy: "selma",
            members: [
                SeedSpaceMemberSpec(user: "selma", role: .owner),
                SeedSpaceMemberSpec(user: "damir", role: .moderator),
                SeedSpaceMemberSpec(user: "amina", role: .member),
                SeedSpaceMemberSpec(user: "emir", role: .member),
                SeedSpaceMemberSpec(user: "nermin", role: .member)
            ]
        ),
        SeedSpaceSpec(
            key: "film",
            slug: "ibu-film-club",
            name: "IBU Film Club",
            description: "Weekly screenings and a student film night on the lawn.",
            kind: .community,
            visibility: .public,
            isOfficial: false,
            createdBy: "lejla",
            members: [
                SeedSpaceMemberSpec(user: "lejla", role: .owner),
                SeedSpaceMemberSpec(user: "amina", role: .member),
                SeedSpaceMemberSpec(user: "maja", role: .member),
                SeedSpaceMemberSpec(user: "sara", role: .member)
            ]
        ),
        SeedSpaceSpec(
            key: "green",
            slug: "campus-green",
            name: "Campus Green",
            description: "Hikes, planting days, and whoever brought baklava.",
            kind: .community,
            visibility: .public,
            isOfficial: false,
            createdBy: "emir",
            members: [
                SeedSpaceMemberSpec(user: "emir", role: .owner),
                SeedSpaceMemberSpec(user: "amina", role: .member),
                SeedSpaceMemberSpec(user: "haris", role: .member),
                SeedSpaceMemberSpec(user: "yusuf", role: .member)
            ]
        )
    ]

    static let events: [SeedEventSpec] = [
        SeedEventSpec(
            key: "career",
            title: "Career Fair",
            description: "Meet campus partners hiring this semester. Hall A.",
            startOffset: -90 * 60,
            endOffset: 3 * 3_600,
            place: "main",
            host: "damir",
            space: "se",
            capacity: 200
        ),
        SeedEventSpec(
            key: "openday",
            title: "IBU Open Day",
            description: "Tours, labs, and a lawn full of future freshmen.",
            startOffset: 26 * 3_600,
            endOffset: 32 * 3_600,
            place: "lawn",
            host: "elma",
            space: nil,
            capacity: 400
        ),
        SeedEventSpec(
            key: "film",
            title: "Film Night on the Lawn",
            description: "Blankets, a projector, and a student short-film block.",
            startOffset: 3 * 24 * 3_600,
            endOffset: 3 * 24 * 3_600 + 3 * 3_600,
            place: "lawn",
            host: "lejla",
            space: "film",
            capacity: 80
        )
    ]

    static let posts: [SeedPostSpec] = [
        SeedPostSpec(
            key: "1", author: "emir",
            caption: "Late light on the lawn. #ibu #campus",
            place: "lawn",
            altText: "Golden hour over the IBU campus lawn",
            hoursAgo: 2, red: 0.75, green: 0.52, blue: 0.22, width: 1080, height: 1350
        ),
        SeedPostSpec(
            key: "2", author: "emir",
            caption: "A-12 after midnight. The arm finally moves. #robotics #ibu",
            space: "robotics", place: "main",
            altText: "A robotics workbench with a small arm and scattered tools",
            hoursAgo: 18, red: 0.18, green: 0.22, blue: 0.30, width: 1080, height: 1080
        ),
        SeedPostSpec(
            key: "3", author: "lejla",
            caption: "Studio critique day. Bring thicker skin. #architecture #burch",
            place: "main",
            altText: "Architecture models lined up on a studio table",
            hoursAgo: 5, red: 0.82, green: 0.74, blue: 0.62, width: 1080, height: 1350
        ),
        SeedPostSpec(
            key: "4", author: "lejla",
            caption: "Blankets, projector, lawn. Thursday. @amina.hodzic you in? #filmnight #ibu",
            space: "film", event: "film", place: "lawn",
            altText: "A projector and blankets set out on the campus lawn",
            hoursAgo: 8, red: 0.12, green: 0.12, blue: 0.18, width: 1600, height: 900
        ),
        SeedPostSpec(
            key: "5", author: "sara",
            caption: "Cafeteria espresso hits different during midterms. #ibu #campus",
            place: "cafeteria",
            altText: "A coffee cup on a cafeteria table",
            hoursAgo: 3, red: 0.42, green: 0.28, blue: 0.18, width: 1080, height: 1080
        ),
        SeedPostSpec(
            key: "6", author: "sara",
            caption: "Third floor of the library is the quiet one. You're welcome. #library #ibuweek",
            place: "library",
            altText: "Rows of desks in the IBU library",
            hoursAgo: 28, red: 0.32, green: 0.38, blue: 0.34, width: 1080, height: 1350
        ),
        SeedPostSpec(
            key: "7", author: "nermin",
            caption: "If C building flickers tonight, that is a lab, not a ghost. #ibu",
            place: "main",
            altText: "The corridor of C building with overhead lights",
            hoursAgo: 11, red: 0.70, green: 0.70, blue: 0.68, width: 1080, height: 1080
        ),
        SeedPostSpec(
            key: "8", author: "yusuf",
            caption: "First week at Burch. Ilidža is prettier than the brochure. #ibu #campus",
            place: "lawn",
            altText: "The main facade of International Burch University",
            hoursAgo: 40, red: 0.20, green: 0.40, blue: 0.28, width: 1080, height: 1350
        ),
        SeedPostSpec(
            key: "9", author: "damir",
            caption: "Career Fair is on — Hall A, now. Bring CVs. #careerfair #ibu",
            space: "se", event: "career", place: "main",
            altText: "Booths being set up for the IBU career fair",
            hoursAgo: 1, red: 0.10, green: 0.18, blue: 0.38, width: 1600, height: 900
        ),
        SeedPostSpec(
            key: "10", author: "damir",
            caption: "SE office hours moved to C-204 this week. #software",
            space: "se",
            altText: "A faculty office door with a nameplate",
            hoursAgo: 22, red: 0.45, green: 0.45, blue: 0.48, width: 1080, height: 1080
        ),
        SeedPostSpec(
            key: "11", author: "selma",
            caption: "Robotics workshop Saturday. Soldering irons provided, patience not. #robotics #ibu",
            space: "robotics", place: "main",
            altText: "Students around a robotics club workbench",
            hoursAgo: 15, red: 0.16, green: 0.34, blue: 0.50, width: 1080, height: 1350
        ),
        SeedPostSpec(
            key: "12", author: "amina",
            caption: "Senior project week. The demo gods are listening. #ibu #ibuweek",
            place: "library",
            altText: "A laptop and notes on a library desk",
            hoursAgo: 6, red: 0.55, green: 0.12, blue: 0.18, width: 1080, height: 1350
        ),
        SeedPostSpec(
            key: "13", author: "elma",
            caption: "Open Day is tomorrow. Architecture studio will be open. #openday #burch",
            event: "openday", place: "lawn",
            altText: "Banners being hung along the campus path",
            hoursAgo: 4, red: 0.88, green: 0.78, blue: 0.55, width: 1600, height: 900
        ),
        SeedPostSpec(
            key: "14", author: "maja",
            caption: "Petition for more benches between A and C. Who is with me. #campus #ibu",
            place: "lawn",
            altText: "A path between faculty buildings on campus",
            hoursAgo: 9, red: 0.30, green: 0.50, blue: 0.38, width: 1080, height: 1080
        ),
        SeedPostSpec(
            key: "15", author: "haris",
            caption: "Found the baklava. Campus Green did not lie. #ibu",
            space: "green", place: "cafeteria",
            altText: "A tray of baklava on a cafeteria table",
            hoursAgo: 7, red: 0.78, green: 0.58, blue: 0.28, width: 1080, height: 1080
        )
    ]
}
