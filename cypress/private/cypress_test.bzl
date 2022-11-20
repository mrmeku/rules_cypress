load("@aspect_rules_js//js:libs.bzl", "js_binary_lib", "js_lib_helpers")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

_attrs = dicts.add(js_binary_lib.attrs, {
    "runner": attr.label(
        doc = """JS file to call into the cypress module api

See https://docs.cypress.io/guides/guides/module-api
        """,
        allow_single_file = [".js"],
        mandatory = True,
    ),
})

def _impl(ctx):
    cypress_bin = ctx.toolchains["@aspect_rules_cypress//cypress:toolchain_type"].cypressinfo.target_tool_path
    cypress_files = ctx.toolchains["@aspect_rules_cypress//cypress:toolchain_type"].cypressinfo.tool_files

    files = ctx.files.data[:] + cypress_files

    fixed_args = [
        cypress_bin,
        ctx.file.runner.short_path,
    ]

    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_cypess",
        log_prefix_rule = "cypress_node_test",
        fixed_args = fixed_args,
    )

    runfiles = ctx.runfiles(
        files = files,
        transitive_files = js_lib_helpers.gather_files_from_js_providers(
            targets = ctx.attr.data,
            include_transitive_sources = ctx.attr.include_transitive_sources,
            include_declarations = ctx.attr.include_declarations,
            include_npm_linked_packages = ctx.attr.include_npm_linked_packages,
        ),
    ).merge(launcher.runfiles).merge_all([
        target[DefaultInfo].default_runfiles
        for target in ctx.attr.data
    ])

    return [
        DefaultInfo(
            executable = launcher.executable,
            runfiles = runfiles,
        ),
    ]

lib = struct(
    attrs = _attrs,
    implementation = _impl,
)
