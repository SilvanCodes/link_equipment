use lychee_lib::{
    extract::Extractor, Collector, FileType, Input, InputContent, InputSource, Request, Result,
};
use reqwest::Url;
use rustler::NifStruct;
use tokio_stream::StreamExt;

#[derive(Debug, NifStruct)]
#[module = "LinkEquipment.Link"]
struct Link {
    url: Uri,
    source_document_url: Uri,
    html_element: Option<String>,
    element_attribute: Option<String>,
}

impl From<Request> for Link {
    fn from(value: Request) -> Self {
        let source = match value.source {
            InputSource::RemoteUrl(url) => *url,
            _ => panic!("only remote urls supported"),
        };

        let url = match Url::parse(value.uri.as_str()) {
            Ok(url) => url,
            Err(url::ParseError::RelativeUrlWithoutBase) => Url::options()
                .base_url(Some(&source))
                .parse(value.uri.as_str())
                .unwrap(),

            Err(_) => panic!("cant parse url"),
        };

        Self {
            url: url.into(),
            source_document_url: source.into(),
            html_element: value.element,
            element_attribute: value.attribute,
        }
    }
}

#[derive(Debug, NifStruct)]
#[module = "URI"]
struct Uri {
    authority: Option<String>,
    fragment: Option<String>,
    host: Option<String>,
    path: Option<String>,
    port: Option<u16>,
    query: Option<String>,
    scheme: Option<String>,
    userinfo: Option<String>,
}

impl From<reqwest::Url> for Uri {
    fn from(value: reqwest::Url) -> Self {
        Self {
            authority: value.domain().map(str::to_string),
            fragment: None,
            host: value.domain().map(str::to_string),
            path: Some(value.path().to_string()),
            port: value.port(),
            query: value.query().map(str::to_string),
            scheme: Some(value.scheme().to_string()),
            userinfo: None,
        }
    }
}

async fn do_collect_links(url: Url) -> Result<Vec<Request>> {
    // Collect all links from the following inputs
    let inputs = vec![Input {
        source: InputSource::RemoteUrl(Box::new(url)),
        file_type_hint: None,
        excluded_paths: None,
    }];

    Collector::new(None) // base
        .skip_missing_inputs(false) // don't skip missing inputs? (default=false)
        .use_html5ever(false) // use html5ever for parsing? (default=false)
        .collect_links(inputs) // base url or directory
        .collect::<Result<Vec<_>>>()
        .await
}

#[rustler::nif]
fn collect_links(url: String) -> std::result::Result<Vec<Link>, ()> {
    let url = Url::parse(&url).unwrap();
    let rt = tokio::runtime::Runtime::new().unwrap();
    let future = do_collect_links(url);
    let result = rt.block_on(future);

    match result {
        Result::Ok(links) => Ok(links.into_iter().map(Link::from).collect::<Vec<_>>()),
        Result::Err(_) => Err(()),
    }
}

#[derive(Debug, NifStruct)]
#[module = "LinkEquipment.RawLink"]
struct RawLink {
    text: String,
    element: Option<String>,
    attribute: Option<String>,
}

#[rustler::nif]
fn extract_links(source: String) -> Vec<RawLink> {
    let input_content = InputContent::from_string(source.as_str(), FileType::Html);

    Extractor::new(false, true)
        .extract(&input_content)
        .into_iter()
        .map(|raw_uri| RawLink {
            text: raw_uri.text,
            element: raw_uri.element,
            attribute: raw_uri.attribute,
        })
        .collect::<Vec<_>>()
}

rustler::init!("Elixir.LinkEquipment.Lychee");
